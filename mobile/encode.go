package txqr

import (
	"github.com/divan/txqr"
)

// Encoder wraps txqr.Encoder for mobile use.
// gomobile cannot export []string, so we store chunks internally
// and expose them via index-based access.
type Encoder struct {
	encoder *txqr.Encoder
	chunks  []string
}

// NewEncoder creates a new encoder with the given chunk length.
// Chunk length determines the size of data per QR code frame.
// Recommended values: 100-500 for reliable scanning.
func NewEncoder(chunkLen int) *Encoder {
	return &Encoder{
		encoder: txqr.NewEncoder(chunkLen),
	}
}

// Encode encodes the data string into fountain-coded chunks.
// After calling this, use ChunkCount() and GetChunk(i) to retrieve the frames.
func (e *Encoder) Encode(data string) error {
	chunks, err := e.encoder.Encode(data)
	if err != nil {
		return err
	}
	e.chunks = chunks
	return nil
}

// ChunkCount returns the number of encoded chunks.
func (e *Encoder) ChunkCount() int {
	return len(e.chunks)
}

// GetChunk returns the chunk at index i.
// Index should be in range [0, ChunkCount()).
// Returns empty string if index is out of bounds.
func (e *Encoder) GetChunk(i int) string {
	if i < 0 || i >= len(e.chunks) {
		return ""
	}
	return e.chunks[i]
}

// SetRedundancyFactor changes the redundancy factor for encoding.
// Higher values produce more chunks, increasing reliability at the cost of time.
// Default is 2.0.
func (e *Encoder) SetRedundancyFactor(rf float64) {
	e.encoder.SetRedundancyFactor(rf)
}
