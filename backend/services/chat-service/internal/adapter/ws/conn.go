package ws

import (
	"time"

	"github.com/gorilla/websocket"
	"github.com/rs/zerolog/log"
)

const (
	sendBufferSize = 256
	writeWait      = 10 * time.Second
	pongWait       = 10 * time.Second
	pingInterval   = 30 * time.Second
)

type WSConn struct {
	conn   *websocket.Conn
	send   chan []byte
	closed bool
	userID string
}

func NewWSConn(conn *websocket.Conn, userID string) *WSConn {
	return &WSConn{
		conn:   conn,
		send:   make(chan []byte, sendBufferSize),
		userID: userID,
	}
}

func (c *WSConn) Send(data []byte) {
	if c.closed {
		return
	}
	select {
	case c.send <- data:
	default:
		log.Warn().Str("user_id", c.userID).Msg("ws send buffer full, dropping client")
		c.Close()
	}
}

func (c *WSConn) Close() {
	if c.closed {
		return
	}
	c.closed = true
	close(c.send)
	_ = c.conn.Close()
}

func (c *WSConn) WritePump() {
	ticker := time.NewTicker(pingInterval)
	defer func() {
		ticker.Stop()
		c.Close()
	}()

	for {
		select {
		case msg, ok := <-c.send:
			_ = c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				_ = c.conn.WriteMessage(websocket.CloseMessage, nil)
				return
			}
			if err := c.conn.WriteMessage(websocket.TextMessage, msg); err != nil {
				return
			}
		case <-ticker.C:
			_ = c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

func (c *WSConn) ReadPump(onMessage func(userID string, data []byte), onClose func(userID string)) {
	defer func() {
		onClose(c.userID)
		c.Close()
	}()

	c.conn.SetReadDeadline(time.Now().Add(pingInterval + pongWait))
	c.conn.SetPongHandler(func(string) error {
		c.conn.SetReadDeadline(time.Now().Add(pingInterval + pongWait))
		return nil
	})

	for {
		_, message, err := c.conn.ReadMessage()
		if err != nil {
			return
		}
		onMessage(c.userID, message)
	}
}
