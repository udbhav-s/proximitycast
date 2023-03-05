# Proximitycast

An app that uses the homomorphic properties of Paillier encryption to privately detect if two parties are within proximity of each other to find ongoing events and broadcast them. Based on the [Louis Protocol](https://cs.uwaterloo.ca/~uhengart/courses/cs497/f07/locpriv_slides.pdf). The core algorithm for calculating proximity is written in C++ using libpaillier and GMP. It is compiled for Android using the NDK and called in Flutter via the Dart FFI. A Node.js server is used as a verifying third party which calls a compiled binary of the code to verify the calculated distance ciphertext. The app uses WebRTC to exchange the ciphertexts of the protocol and also for opening a chat between users.  

More info on [Devpost page](https://devpost.com/software/proximitycast)  

[Demo on YouTube](https://www.youtube.com/watch?v=7CGoqzp0Wg4)

C++ source in: `./src`

Node server: `./server`
