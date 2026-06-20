package app

import (
	"sync"
	"time"
)

const (
	defaultCacheTTL     = 10 * time.Second
	defaultCacheMissTTL = 2 * time.Second
)

type Cache[T any] interface {
	Get(key string) (T, bool)
	Put(key string, value T)
	PutMissing(key string)
	IsMissing(key string) bool
	Delete(key string)
	Clear()
}

type MemoryCache[T any] struct {
	mu      sync.RWMutex
	values  map[string]cacheEntry[T]
	ttl     time.Duration
	missTTL time.Duration
	clock   Clock
}

type cacheEntry[T any] struct {
	value     T
	found     bool
	expiresAt time.Time
}

func NewMemoryCache[T any]() *MemoryCache[T] {
	return NewMemoryCacheWithClock[T](defaultCacheTTL, defaultCacheMissTTL, NewSystemClock())
}

func NewMemoryCacheWithClock[T any](ttl time.Duration, missTTL time.Duration, clock Clock) *MemoryCache[T] {
	if ttl <= 0 {
		ttl = defaultCacheTTL
	}
	if missTTL <= 0 {
		missTTL = defaultCacheMissTTL
	}
	if clock == nil {
		clock = NewSystemClock()
	}
	return &MemoryCache[T]{
		values:  make(map[string]cacheEntry[T]),
		ttl:     ttl,
		missTTL: missTTL,
		clock:   clock,
	}
}

func (c *MemoryCache[T]) Get(key string) (T, bool) {
	if entry, ok := c.getEntry(key); ok && entry.found {
		return entry.value, true
	}
	var zero T
	return zero, false
}

func (c *MemoryCache[T]) Put(key string, value T) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.values[key] = cacheEntry[T]{
		value:     value,
		found:     true,
		expiresAt: c.clock.Now().Add(c.ttl),
	}
}

func (c *MemoryCache[T]) PutMissing(key string) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.values[key] = cacheEntry[T]{
		found:     false,
		expiresAt: c.clock.Now().Add(c.missTTL),
	}
}

func (c *MemoryCache[T]) IsMissing(key string) bool {
	entry, ok := c.getEntry(key)
	return ok && !entry.found
}

func (c *MemoryCache[T]) Delete(key string) {
	c.mu.Lock()
	defer c.mu.Unlock()
	delete(c.values, key)
}

func (c *MemoryCache[T]) Clear() {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.values = make(map[string]cacheEntry[T])
}

func (c *MemoryCache[T]) getEntry(key string) (cacheEntry[T], bool) {
	c.mu.RLock()
	entry, ok := c.values[key]
	c.mu.RUnlock()
	if !ok {
		return cacheEntry[T]{}, false
	}
	if !entry.expiresAt.After(c.clock.Now()) {
		c.mu.Lock()
		if current, exists := c.values[key]; exists && current.expiresAt.Equal(entry.expiresAt) {
			delete(c.values, key)
		}
		c.mu.Unlock()
		return cacheEntry[T]{}, false
	}
	return entry, true
}
