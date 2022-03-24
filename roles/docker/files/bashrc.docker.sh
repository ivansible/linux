drup() {
    local file=$1
    local name
    name=$(basename "$file")
    name=${name%.*}
    docker stack deploy "$name" -c "$file"
}
