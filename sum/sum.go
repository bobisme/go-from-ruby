package main

// must be the main package

// Importing C is required even though it's not used in this file.

import "C"
import (
	"strconv"
	"unsafe"
)

// There must not be a space in "//export" otherwile the function will not get
// exported.
// The export directive must have the exact, case-sensetive function name.

type Err int

const (
	ErrNoNegatives Err = iota + 1
	ErrUnknown
)

//export Add
func Add(a int, b int) int {
	return a + b
}

//export Sum
func Sum(intList unsafe.Pointer, length int) int {
	// The wicked incantation necessary to convert the array pointed to by the
	// intList pointer into a slice of the correct type.
	// Cast intList // (...)(intList)
	//   into a pointer to // (*...)(...
	//   an array of ints // *[...]int)...
	//     of size 2^30 // [1 << 30]int
	// and slice it // (intlist)[...]
	//   from the beginning // [:...]
	//   up to the expected length // [:length]
	//   with a cap equal to the length. // [:length:length]
	intSlice := (*[1 << 30]int)(intList)[:length:length]

	if len(intSlice) == 0 {
		return 0
	}

	acc := 0
	for _, x := range intSlice {
		acc += x
	}
	return acc
}

// ToInt converts _positive_ integer strings to integers.
// Out should be an [1]int.
//export ToInt
func ToInt(in *C.char, out unsafe.Pointer) (errorCode Err) {
	// Convert the input c string to a go string.
	a := C.GoString(in)
	// Normal go stuff.
	i, err := strconv.Atoi(a)
	if err != nil {
		return ErrUnknown
	}
	// Stupid error condition for example purposes.
	if i < 0 {
		return ErrNoNegatives
	}
	// Cast the output pointer to a 1-length int array and assign the
	// resulting value there.
	(*[1]int)(out)[0] = i
	return 0
}

// FromInt converts _positive_ integer to a string.
// Out is **char, a pointer to a string, a [1]*C.char.
//export FromInt
func FromInt(in int, out unsafe.Pointer) (error *C.char) {
	// Stupid error condition for example purposes.
	if in < 0 {
		return C.CString("I said no negatives!")
	}
	// Normal go stuff.
	a := strconv.Itoa(in)
	// Convert the go string to a c string and assign its address to the first
	// block of memory pointed to by out.
	(*[1]*C.char)(out)[0] = C.CString(a)
	return nil
}

// main is required even though it is not used
func main() {}
