// // testing just the formula for maxBet calculation
// const STARTING_POOL_BALANCE = 30000;
// let BET = 100;

// // vars for maxBetCal function
// let _gamesCounter = 0;
// let _betFlip = 0;
// let _colorBet = 0;
// let _betFlipSquare = 0;
// let _colorBetSquare = 0;
// let _betFlipVariance = 0;
// let _colorBetVariance = 0;
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
//     _colorBet = colorB;
//     _betFlipSquare = pokerB * pokerB;
//     _colorBetSquare = colorB * colorB;
//   }

//   if (_gamesCounter > 1) {
//     _betFlip = ((_gamesCounter - 1) * _betFlip + pokerB) /_gamesCounter;
//     _colorBet = ((_gamesCounter - 1) * _colorBet + colorB) / _gamesCounter;
//     _betFlipSquare = ((_gamesCounter - 1) * _betFlipSquare + (pokerB * pokerB)) / _gamesCounter;
//     _colorBetSquare = ((_gamesCounter - 1) * _colorBetSquare + (colorB * colorB)) / _gamesCounter;
//     _betFlipVariance = _betFlipSquare - (_betFlip * _betFlip);
//     _colorBetVariance = _colorBetSquare - (_colorBet * _colorBet);
//     const Fn = _betFlip + (Math.sqrt(_betFlipVariance) * 10);
//     const Cn = _colorBet + (Math.sqrt(_colorBetVariance) * 10);

//     ////////////////////////////////
//     console.log(
//       '_betFlip:', _betFlip,
//       '_colorBet:', _colorBet,
//       '_betFlipSquare:', _betFlipSquare,
//       '_colorBetSquare:', _colorBetSquare,
//       '_betFlipVariance:', _betFlipVariance,
//       '_colorBetVariance:', _colorBetVariance,
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
//   startGame(BET);
//   finishGame(BET);
//   console.log('POOL_AMOUNT:', poolBalance, 'ITERATION:', i, 'GAMES_COUNTER:', _gamesCounter, 'MAX_BET:', _maxBet)
//   BET += 2;
// }
