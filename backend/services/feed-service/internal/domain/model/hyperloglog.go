package model

import (
	"crypto/sha1"
	"encoding/binary"
	"errors"
	"math"
	"math/bits"
)

const (
	HyperLogLogPrecision = 14
	hyperLogLogBuckets   = 1 << HyperLogLogPrecision
)

var ErrInvalidHyperLogLogState = errors.New("invalid hyperloglog state")

type HyperLogLog struct {
	registers []uint8
}

func NewHyperLogLog() *HyperLogLog {
	return &HyperLogLog{
		registers: make([]uint8, hyperLogLogBuckets),
	}
}

func HyperLogLogFromBytes(raw []byte) (*HyperLogLog, error) {
	if len(raw) == 0 {
		return NewHyperLogLog(), nil
	}
	if len(raw) != hyperLogLogBuckets {
		return nil, ErrInvalidHyperLogLogState
	}

	registers := make([]uint8, len(raw))
	copy(registers, raw)

	return &HyperLogLog{registers: registers}, nil
}

func (h *HyperLogLog) Bytes() []byte {
	if h == nil {
		return nil
	}
	raw := make([]byte, len(h.registers))
	copy(raw, h.registers)
	return raw
}

func (h *HyperLogLog) AddString(value string) bool {
	if h == nil {
		return false
	}
	sum := sha1.Sum([]byte(value))
	return h.addHash(binary.BigEndian.Uint64(sum[:8]))
}

func (h *HyperLogLog) Count() uint64 {
	if h == nil {
		return 0
	}

	alpha := 0.7213 / (1.0 + 1.079/float64(hyperLogLogBuckets))
	sum := 0.0
	zeros := 0
	for _, register := range h.registers {
		sum += math.Pow(2.0, -float64(register))
		if register == 0 {
			zeros++
		}
	}

	estimate := alpha * float64(hyperLogLogBuckets*hyperLogLogBuckets) / sum
	if estimate <= 2.5*float64(hyperLogLogBuckets) && zeros > 0 {
		estimate = float64(hyperLogLogBuckets) * math.Log(float64(hyperLogLogBuckets)/float64(zeros))
	}

	if estimate < 0 {
		return 0
	}
	return uint64(math.Round(estimate))
}

func (h *HyperLogLog) addHash(hash uint64) bool {
	idx := hash >> (64 - HyperLogLogPrecision)
	w := (hash << HyperLogLogPrecision) | (1 << (HyperLogLogPrecision - 1))
	rank := uint8(bits.LeadingZeros64(w) + 1)

	maxRank := uint8(64-HyperLogLogPrecision) + 1
	if rank > maxRank {
		rank = maxRank
	}

	if h.registers[idx] >= rank {
		return false
	}
	h.registers[idx] = rank
	return true
}
