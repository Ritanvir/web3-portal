Web3 Portal MVP
Token Listing + Liquidity Creation (Uniswap V2 – Local Hardhat)

This project is a Web3 Token Listing Portal where:

A user pays a listing fee (USDT)

Then creates a Token/XYZ liquidity pool

LP tokens are sent directly to the lister

Built with:

 Solidity (0.8.20)

 Hardhat

 MetaMask

 Next.js + Ethers v6

 Local Uniswap V2 (Factory + Router + Pair)

 Smart Contracts
 MockERC20

Used for:

USDT

XYZ

ABC

ABC2

Has mint() for local testing

 ListingAndLiquidity

Main logic contract:

payListingFee(address token)
createLiquidity(...)


Rules:

Must pay listing fee first

Only the lister can create liquidity

Liquidity can be created only once

Refunds unused tokens automatically

 Setup Guide (Step-by-Step)
 Install Dependencies
cd contracts
npm install

 Start Local Hardhat Node
npx hardhat node


Keep this running.

 Deploy Contracts

Open another terminal:

cd contracts
npx hardhat run scripts/deploy.js --network localhost


You will see:

USDT: 0x...
XYZ: 0x...
ABC: 0x...
ABC2: 0x...
Router: 0x...
App: 0x...


Copy these addresses.

 Setup Frontend .env.local

Inside frontend:

NEXT_PUBLIC_RPC=http://127.0.0.1:8545
NEXT_PUBLIC_CHAIN_ID=31337

NEXT_PUBLIC_USDT=0x...
NEXT_PUBLIC_XYZ=0x...
NEXT_PUBLIC_ABC=0x...
NEXT_PUBLIC_ABC2=0x...
NEXT_PUBLIC_ROUTER=0x...
NEXT_PUBLIC_APP=0x...


Restart frontend:

npm run dev


