# 1. Bauen
./build.sh

# 2. Eigenes Schlüsselpaar erzeugen (du bist der Empfänger)
PARAMS=$(./bin/dhparam)
M=$(echo "$PARAMS"    | awk '/^m:/{print $2}')
G=$(echo "$PARAMS"    | awk '/^g:/{print $2}')
MYPUB=$(echo "$PARAMS" | awk '/^pub:/{print $2}')
MYPRIV=$(echo "$PARAMS" | awk '/^priv:/{print $2}')

echo "Dein Public Key für dhmsg: $MYPUB"

# 3. Verschlüsseln und sofort entschlüsseln
echo 'Hello World!' | /usr/local/bin/dhmsg "$M" "$G" "$MYPUB" | ./bin/decrypt "$M" "$G" "$MYPRIV"
# Erwartet: Hello World!

# 4. run.sh testen (wie im Kolloquium)
echo 'Hello World!' | /usr/local/bin/dhmsg "$M" "$G" "$MYPUB" | ./run.sh "$M" "$G" "$MYPUB"
