// A simple Go web application which serves static files from the `public`
// folder in the project. By default, it listens on port 8080, though you can
// change that below, if you like.
package main

import (
	"net/http"
)

// The main function is the entry point into the application. It creates a file
// server which will serve static files from the `public` folder, listening on
// port 8080.
func main() {
	http.Handle("/", http.FileServer(http.Dir("public")))
	http.ListenAndServe(":8080", nil)
}
