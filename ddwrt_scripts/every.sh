#!/bin/sh

case $2 in
    days)
        expr `date +%j` % $1 = 0 > /dev/null
        ;;

    weeks)
        expr `date +%V` % $1 = 0 > /dev/null
        ;;

    months)
        expr `date +%m` % $1 = 0 > /dev/null
        ;;
esac