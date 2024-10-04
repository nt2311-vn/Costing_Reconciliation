package main

import (
	"encoding/csv"
	"fmt"
	"log"
	"os"
	"strings"
	"time"
)

func main() {
	f, err := os.Open("src/data/IF.csv")
	if err != nil {
		log.Fatalf("cannot read csv file: %v", err)
	}

	defer f.Close()

	reader := csv.NewReader(f)
	lines, err := reader.ReadAll()

	startTime := time.Now().Unix()

	for _, line := range lines {
		fmt.Println(strings.Join(line, ","))
	}

	endTime := time.Now().Unix()
	fmt.Printf("Reading complete: Took %d\n", endTime-startTime)
}
