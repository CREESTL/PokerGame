// // testing just the formula for maxBet calculation
// const STARTING_POOL_BALANCE = 30000;
// let BET = 100;

// // vars for maxBetCal function
// let _gamesCounter = 0;
// let _betFlip = 0;
// let _betColor = 0;
// let _betFlipSquare = 0;
// let _betColorSquare = 0;
// let _betFlipVariance = 0;
// let _betColorVariance = 0;
// let _maxBet = 1000;

// let poolBalance = STARTING_POOL_BALANCE;

// const play = (bet) => {
//     poolBalance = poolBalance + bet;
//     maxBetCalc(bet, 0);
// }

// // assume user always wins
// const finishGame = (bet) => {
//     poolBalance = poolBalance - (bet * 2);
// }

// const maxBetCalc = (pokerB, colorB) => {
//   const poolAmount = poolBalance;
//   _gamesCounter++;

//   if (_gamesCounter == 1) {
//     if (_maxBet == 0) {
//       _maxBet = poolAmount / 230;
//     };
//     _betFlip = pokerB;
//     _betColor = colorB;
//     _betFlipSquare = pokerB * pokerB;
//     _betColorSquare = colorB * colorB;
//   }

//   if (_gamesCounter > 1) {
//     _betFlip = ((_gamesCounter - 1) * _betFlip + pokerB) /_gamesCounter;
//     _betColor = ((_gamesCounter - 1) * _betColor + colorB) / _gamesCounter;
//     _betFlipSquare = ((_gamesCounter - 1) * _betFlipSquare + (pokerB * pokerB)) / _gamesCounter;
//     _betColorSquare = ((_gamesCounter - 1) * _betColorSquare + (colorB * colorB)) / _gamesCounter;
//     _betFlipVariance = _betFlipSquare - (_betFlip * _betFlip);
//     _betColorVariance = _betColorSquare - (_betColor * _betColor);
//     const Fn = _betFlip + (Math.sqrt(_betFlipVariance) * 10);
//     const Cn = _betColor + (Math.sqrt(_betColorVariance) * 10);

//     ////////////////////////////////
//     console.log(
//       '_betFlip:', _betFlip,
//       '_betColor:', _betColor,
//       '_betFlipSquare:', _betFlipSquare,
//       '_betColorSquare:', _betColorSquare,
//       '_betFlipVariance:', _betFlipVariance,
//       '_betColorVariance:', _betColorVariance,
//       'Fn:', Fn,
//       'Cn:', Cn,
//     )
//     ///////////////////////////////////////////

//     if (_gamesCounter > 3  || Fn < poolAmount / 230 || Cn < poolAmount / 230) {
//       _gamesCounter = 0;

//       if (_maxBet > poolAmount / 109) {
//         _maxBet = poolAmount / 109;
//         return;
//       }

//       if (_maxBet < poolAmount / 230) {
//         _maxBet = poolAmount / 230;
//         return;
//       };

//       if (Fn > Cn) {
//         _maxBet = _maxBet * _maxBet / Fn;
//       } else {
//         _maxBet = _maxBet * _maxBet / Cn;
//       }
      
//     }
//   }
// }

// // 102 games imitation
// for (let i = 0; i < 102; i +=1) {
//   play(BET);
//   finishGame(BET);
//   console.log('POOL_AMOUNT:', poolBalance, 'ITERATION:', i, 'GAMES_COUNTER:', _gamesCounter, 'MAX_BET:', _maxBet)
//   BET += 2;
// }


