const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deployer:", deployer.address);

  // 1) Deploy WETH9
  const WETH9 = await hre.ethers.getContractFactory("WETH9");
  const weth = await WETH9.deploy();
  await weth.waitForDeployment();
  console.log("WETH9:", await weth.getAddress());

  // 2) Deploy UniswapV2 Factory
  const Factory = await hre.ethers.getContractFactory("UniswapV2Factory");
  const factory = await Factory.deploy(deployer.address);
  await factory.waitForDeployment();
  console.log("Factory:", await factory.getAddress());

  // 3) Deploy UniswapV2 Router02
  const Router = await hre.ethers.getContractFactory("UniswapV2Router02");
  const router = await Router.deploy(await factory.getAddress(), await weth.getAddress());
  await router.waitForDeployment();
  console.log("Router:", await router.getAddress());

  // 4) Deploy Mock USDT + XYZ + ABC + ABC2
  const MockERC20 = await hre.ethers.getContractFactory("MockERC20");

  const usdt = await MockERC20.deploy("Tether USD", "USDT", 18);
  await usdt.waitForDeployment();

  const xyz = await MockERC20.deploy("Platform Token", "XYZ", 18);
  await xyz.waitForDeployment();

  const abc = await MockERC20.deploy("User Token", "ABC", 18);
  await abc.waitForDeployment();

  const abc2 = await MockERC20.deploy("User Token 2", "ABC2", 18);
  await abc2.waitForDeployment();

  console.log("USDT:", await usdt.getAddress());
  console.log("XYZ :", await xyz.getAddress());
  console.log("ABC :", await abc.getAddress());
  console.log("ABC2:", await abc2.getAddress());

  // mint test balances (to deployer)
  const mintAmount = hre.ethers.parseUnits("100000", 18);
  await (await usdt.mint(deployer.address, mintAmount)).wait();
  await (await xyz.mint(deployer.address, mintAmount)).wait();
  await (await abc.mint(deployer.address, mintAmount)).wait();
  await (await abc2.mint(deployer.address, mintAmount)).wait();

  // 5) Deploy ListingAndLiquidity
  const ListingAndLiquidity = await hre.ethers.getContractFactory("ListingAndLiquidity");
  const listingFee = hre.ethers.parseUnits("50", 18);

  const app = await ListingAndLiquidity.deploy(
    await usdt.getAddress(),
    await xyz.getAddress(),
    await router.getAddress(),
    listingFee
  );
  await app.waitForDeployment();
  console.log("App:", await app.getAddress());

  console.log("\n--- ENV for frontend ---");
  console.log("NEXT_PUBLIC_RPC=http://127.0.0.1:8545");
  console.log("NEXT_PUBLIC_CHAIN_ID=31337");
  console.log("NEXT_PUBLIC_USDT=", await usdt.getAddress());
  console.log("NEXT_PUBLIC_XYZ=", await xyz.getAddress());
  console.log("NEXT_PUBLIC_ABC=", await abc.getAddress());
  console.log("NEXT_PUBLIC_ABC2=", await abc2.getAddress());
  console.log("NEXT_PUBLIC_ROUTER=", await router.getAddress());
  console.log("NEXT_PUBLIC_APP=", await app.getAddress());
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
