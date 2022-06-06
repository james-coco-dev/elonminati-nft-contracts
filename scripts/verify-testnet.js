require('dotenv').config();
const hre = require('hardhat');

const tokenVerify = async () => {
  await hre.run('verify:verify', {
    address: '0x9754E98596540aE80214637a37BC2E6aF42D6EfF'
  })
}

const buyTokenVerify = async () => {
  await hre.run('verify:verify', {
    address: '0x5Cf67Af1CB5D84Cf575D5698f5DEa815f93E2292',
    constructorArguments: [
      '0x92130126f599Eb70A5780F297DB18cfE1FceB3bF'
    ]
  })
}

const main = async () => {
  await tokenVerify()
  // await buyTokenVerify()
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
