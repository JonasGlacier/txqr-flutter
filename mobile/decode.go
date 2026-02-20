package txqr // package should have this name to work properly with gomobile

import (
	"fmt"
	"strings"
	"time"

	"github.com/divan/txqr"
	"github.com/pyk/byten"
)

// Decoder implements txqr wrapper around protocol decoder.
type Decoder struct {
	*txqr.Decoder

	progress int
	speed    int // avg reading speed in bytes/sec
	start    time.Time

	lastChunk    time.Time // last chunk decode request
	readInterval time.Duration

	// Progress tracking (replaces the stub Read()/Length() methods in the core).
	// We parse the frame header ourselves so we can count unique blocks received.
	blocksReceived int
	chunkLen       int
	totalBytes     int
	seenHeaders    map[string]struct{}
}

// NewDecoder creates new txqr decoder.
func NewDecoder() *Decoder {
	return &Decoder{
		Decoder:     txqr.NewDecoder(),
		seenHeaders: make(map[string]struct{}),
	}
}

// Decode takes a single chunk of data and decodes it.
func (d *Decoder) Decode(data string) error {
	// mobile app can still try to decode any detected QR codes,
	// so we're ignoring them here
	if d.IsCompleted() {
		return nil
	}

	if err := d.Validate(data); err != nil {
		return err
	}

	// Parse header to extract metadata and check for duplicates.
	// Frame format: blockCode/chunkLen/total|payload
	header, chunkLen, total := parseFrameHeader(data)
	isNewBlock := header != "" && !d.markSeen(header)

	// Capture metadata from the first successfully parsed frame.
	if chunkLen > 0 && d.chunkLen == 0 {
		d.chunkLen = chunkLen
		d.totalBytes = total
	}

	// Mark start time on first valid txqr frame.
	if d.start.IsZero() {
		d.start = time.Now()
	}

	// Track interval between chunks.
	if !d.lastChunk.IsZero() {
		d.readInterval = time.Now().Sub(d.lastChunk)
	}
	d.lastChunk = time.Now()

	// Pass frame to core decoder.
	if err := d.Decoder.Decode(data); err != nil {
		return err
	}

	// Only update progress when the block was genuinely new.
	if isNewBlock {
		d.blocksReceived++
		d.recalcProgress()
	}

	return nil
}

// parseFrameHeader extracts the header string, chunkLen, and total from a
// TXQR frame ("blockCode/chunkLen/total|payload"). Returns zero values on failure.
func parseFrameHeader(frame string) (header string, chunkLen int, total int) {
	idx := strings.IndexByte(frame, '|')
	if idx == -1 {
		return "", 0, 0
	}
	header = frame[:idx]
	var blockCode int64
	if _, err := fmt.Sscanf(header, "%d/%d/%d", &blockCode, &chunkLen, &total); err != nil {
		return "", 0, 0
	}
	return header, chunkLen, total
}

// markSeen records the header as seen. Returns true if it was already seen.
func (d *Decoder) markSeen(header string) bool {
	if _, ok := d.seenHeaders[header]; ok {
		return true
	}
	d.seenHeaders[header] = struct{}{}
	return false
}

// recalcProgress updates progress percentage and speed estimate.
func (d *Decoder) recalcProgress() {
	if d.totalBytes == 0 || d.chunkLen == 0 || d.blocksReceived == 0 {
		return
	}

	elapsed := time.Since(d.start)
	if elapsed > 0 {
		// Approximate throughput: each block carries at most chunkLen bytes.
		bytesApprox := d.blocksReceived * d.chunkLen
		d.speed = bytesApprox * int(time.Second) / int(elapsed)
	}

	// Fountain codes (LT) with default 2× redundancy decode after roughly
	// numSourceChunks * 1.05 unique blocks on average. We use 1.1 as a
	// conservative target so the bar reliably reaches ~90% before completion.
	numSourceChunks := (d.totalBytes + d.chunkLen - 1) / d.chunkLen
	expected := int(float64(numSourceChunks) * 1.2)
	if expected < 1 {
		expected = 1
	}
	d.progress = 100 * d.blocksReceived / expected
	if d.progress > 99 {
		d.progress = 99 // snap to 100% only via Progress() once IsCompleted()
	}
}

// Progress returns reading progress as a percentage (0-100).
// Returns 100 once decoding has completed.
func (d *Decoder) Progress() int {
	if d.IsCompleted() {
		return 100
	}
	return d.progress
}

// Speed returns avg reading speed as a human-readable string, e.g. "45.2 KB/s".
func (d *Decoder) Speed() string {
	if d.IsCompleted() && d.totalBytes > 0 && !d.start.IsZero() {
		// Use actual total bytes and elapsed time for the final figure.
		elapsed := time.Since(d.start)
		if elapsed > 0 {
			finalSpeed := d.totalBytes * int(time.Second) / int(elapsed)
			return fmt.Sprintf("%s/s", byten.Size(int64(finalSpeed)))
		}
	}
	return fmt.Sprintf("%s/s", byten.Size(int64(d.speed)))
}

// ReadInterval returns the latest read interval in ms.
func (d *Decoder) ReadInterval() int64 {
	return int64(d.readInterval / time.Millisecond)
}

// TotalTime returns the total scan duration in human-readable form.
func (d *Decoder) TotalTime() string {
	dur := time.Since(d.start)
	return formatDuration(dur)
}

// TotalTimeMs returns the total scan duration in milliseconds.
func (d *Decoder) TotalTimeMs() int64 {
	if d.start.IsZero() {
		return 0
	}
	return int64(time.Since(d.start) / time.Millisecond)
}

// TotalSize returns the data size in human-readable form.
func (d *Decoder) TotalSize() string {
	return byten.Size(int64(d.totalBytes))
}

// formatDuration trims sub-100ms noise: "12.232312313s" → "12.2s".
func formatDuration(d time.Duration) string {
	if d > time.Second {
		d = d - d%(100*time.Millisecond)
	}
	return d.String()
}

// Reset resets the decoder, preparing it for the next run.
func (d *Decoder) Reset() {
	d.Decoder.Reset()

	d.progress = 0
	d.speed = 0
	d.start = time.Time{}
	d.lastChunk = time.Time{}
	d.readInterval = 0
	d.blocksReceived = 0
	d.chunkLen = 0
	d.totalBytes = 0
	d.seenHeaders = make(map[string]struct{})
}
