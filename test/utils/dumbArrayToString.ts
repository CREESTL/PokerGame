export const dumbArrayToString = (arr:any[]) => {
    return JSON.stringify(arr.map(e => e.toString()));
}
