const dumbArrayToString = (arr = []) => {
    return JSON.stringify(arr.map(e => e.toString()));
}

module.exports = {
    dumbArrayToString,
}