package main

import (
	"bufio"
	"fmt"
	"net"
	"os"
	"sync"
	"time"
)

var quit = make(chan struct{})

func main() {
	scanner := bufio.NewScanner(os.Stdin)
	var wg sync.WaitGroup

	for scanner.Scan() {
		servAddr := scanner.Text() // read one line for the server addr:port
		if !scanner.Scan() {
			panic("")
		}
		clientAddr := scanner.Text() // read another line for source client:port
		wg.Add(1)
		time.Sleep(2 * time.Millisecond) // pace ourselves
		fmt.Printf("%v->%v\n", clientAddr, servAddr)
		go func(servAddr, clientAddr string) {
			defer wg.Done()
			tcpServAddr, err := net.ResolveTCPAddr("tcp", servAddr)
			if err != nil {
				panic(err)
			}
			tcpClientAddr, err := net.ResolveTCPAddr("tcp", clientAddr)
			if err != nil {
				panic(err)
			}

			conn, err := net.DialTCP("tcp", tcpClientAddr, tcpServAddr)
			if err != nil {
				println("Dial failed:", err.Error())
				return
			}
			conn.SetKeepAlive(false)

			<-quit

			conn.Close()
		}(servAddr, clientAddr)
	}
	fmt.Println("waiting now")
	wg.Wait()
}
