#!/bin/bash
killall -9 node

declare -A baseport    # These must be kept up to date with contlist!
baseport[mnt224]=9000
baseport[ss512]=9500

DKG=$PWD/dkg/DKG_0.8.0/DKG-Executable/

declare -A launch
for curve in mnt224 ss512
do
  for x in `seq 1 4`
  do
    rm -r $DKG/$curve/node$x
    mkdir -p $DKG/$curve/node$x
    ln -s $DKG/../src/node $DKG/$curve/node$x/
    ln -s $DKG/certs $DKG/$curve/node$x/
    ln -s $DKG/$curve.contlist $DKG/$curve/node$x/contlist
    ln -s $DKG/$curve.system.param $DKG/$curve/node$x/system.param
    ln -s $DKG/$curve.pairing.param $DKG/$curve/node$x/pairing.param
    launch["$curve:$x"]="pushd $DKG/$curve/node$x; bash -c \"./node $((${baseport[$curve]}+$x)) certs/$x.pem certs/$x-key.pem contlist 0 0 0&\"; popd"
    echo ${launch["$curve:$x"]}
  done
done

tmux new-session    "${launch[mnt224:1]};${launch[ss512:1]};python run_fifo.py -i 1;cat dc.txt;bash" \;  \
     splitw -h -p 67 "${launch[mnt224:2]};${launch[ss512:2]};python run_fifo.py -i 2;cat dc.txt;bash" \;  \
     splitw -h -p 50 "cd go-ethereum;sleep 5;./build/bin/geth --datadir gdata1 --networkid 10 init genesis.json; env BADGER_SOCK=/tmp/hb1 GETH_SOCK=/tmp/geth1 ./build/bin/geth --datadir gdata1 --nodiscover --port 30301 --networkid 10 --password /dev/null --unlock 0 console;cat ../dc.txt;bash " \;  \
     splitw -v -p 50 "cd go-ethereum;sleep 5;./build/bin/geth --datadir gdata2 --networkid 10 init genesis.json; env BADGER_SOCK=/tmp/hb2 GETH_SOCK=/tmp/geth2 ./build/bin/geth --datadir gdata2 --nodiscover --port 30302 --networkid 10 --password /dev/null --unlock 0 console;cat ../dc.txt;bash " \;  \
     selectp -t 0 \; \
     splitw -v -p 50 "${launch[mnt224:3]};${launch[ss512:3]};python run_fifo.py -i 3;cat dc.txt;bash" \;  \
     selectp -t 2\; \
     splitw -v -p 50 "${launch[mnt224:4]};${launch[ss512:4]};python run_fifo.py -i 4;cat dc.txt;bash"
