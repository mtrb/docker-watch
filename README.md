[![Build Status](https://cloud.drone.io/api/badges/mtrb/docker-watch/status.svg)](https://cloud.drone.io/mtrb/docker-watch)

# docker-watch 

Watch docker container events and logs in a docker-compose style

    [-----------------------------------------------------------------]


                            ****  Docker Watch  ****


                          Docker Version: 18.03.0-ce
                             API Version: 1.37
                         Min API Version: 1.12
                                      OS: linux
                            Architecture: amd64
                          Kernel Version: 4.9.89-boot2docker


    [-----------------------------------------------------------------]

    🛢  | 🛠  | application  |
    🛢  | 🛠  | database     |
    🛢  | 🏁  | application  |
    🛢  | 🏁  | database     |
    🛢  | 💬  | application  | INFO:root:application running
    🛢  | 💬  | database     | INFO:root:databae running
    🛢  | 🔪  | application  |
    🛢  | 🔪  | database     |
    🛢  | ☠️  | application  |
    🛢  | ☠️  | database     |
    🛢  | ✋  | application  |
    🛢  | ✋  | database     |
    🛢  | 🗑  | application  |
    🛢  | 🗑  | database     |

## Usage

**Note on Linux:** Since the [bug SR-648](https://bugs.swift.org/browse/SR-648) is not fixed completely the libFoundation is not linked statically and causes the error 
*"...libFoundation.so: cannot open shared object file"*. To solve this issue install [Swift 5.1 for Ubuntu](https://swift.org/download/).

### Create a docker-watch.yml file

     # Docker Watch test file

        containers:                 # List containers to watch
            - my_application
            - my_database

        display:
            remove_prefix: true    # this will remove "my_" from the log messages
            prefix_end: "_"
            emojis: true           # use emojis in log messages
            colors: true           # use ANSI colors

        filter:                    # filter logs containing the following strings
            - DEBUG

### Run docker-watch

Run the Binary:

    docker-watch
        
Or use the [Docker image](https://hub.docker.com/r/matrb/docker-watch):
    
    docker container run -it --rm \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v `pwd`/docker-watch.yml:/docker-watch.yml \
        matrb/docker-watch


## Build

### Dependencies

Since the application uses  [`SwiftNIO SSL 1.4.x`](https://github.com/apple/swift-nio-ssl/tree/nio-ssl-1.4) libssl is needed.
For Darwin (iOS, macOS, tvOS, ...):

    brew install libressl

For Linux see the Dockerfile

### macOS

Release with Swift stdlib linked statically

    swift build -c release --static-swift-stdlib

Build and run for debugging

    swift run docker-watch

### LINUX Docker image

    docker image build -t docker-watch .
