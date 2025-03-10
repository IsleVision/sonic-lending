import { ethers } from "ethers";
import { useState, useEffect } from "react";
import { useMoralis } from "react-moralis";
import {
  protocolCoreAddress,
  protocolCoreAbi,
  sonkTokenAddress,
  sonkTokenAbi,
  sonicAddress,
  sonicAbi,
  ethAddress,
  ethAbi
} from "../constants";

import DataSection from "../components/DataSection.jsx";
import ControlSection from "../components/ControlSection.jsx";
import CollateralSection from "../components/CollateralSection.jsx";
import PositionSection from "../components/PositionSection.jsx";
import ErrorSection from "../components/ErrorSection.jsx";

export default function App() {
  const [sonkBalance, setSonkBalance] = useState(0);
  const [sonicBalance, setSonicBalance] = useState(0);
  const [earnedTokens, setEarnedTokens] = useState(0);
  const [lendingBalance, setLendingBalance] = useState(0);
  const [borrowBalance, setBorrowBalance] = useState(0);
  const [collateralBalance, setCollateralBalance] = useState(0);
  const [borrowLimit, setBorrowLimit] = useState(0);
  const [liquidationPoint, setLiquidationPoint] = useState(0);

  const { chainId: chainIdHex, isWeb3Enabled } = useMoralis();
  const chainId = parseInt(chainIdHex);

  const coreAddress =
    chainId in protocolCoreAddress ? protocolCoreAddress[chainId] : null;
  const tokenAddress =
    chainId in sonkTokenAddress ? sonkTokenAddress[chainId] : null;
  const baseAssetAddress = chainId in sonicAddress ? sonicAddress[chainId] : null;
  const ethAssetAddress = chainId in ethAddress ? ethAddress[chainId] : null;

  useEffect(() => {
    const getSonkBalance = async () => {
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();
      const tokenContract = new ethers.Contract(
        tokenAddress,
        sonkTokenAbi,
        signer
      );
      const address = await signer.getAddress();
      const rawBalance = await tokenContract.balanceOf(address);
      const balance = Number.parseFloat(
        ethers.utils.formatEther(rawBalance)
      ).toFixed(3);
      setSonkBalance(balance);
    };
    const getSonicBalance = async () => {
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();
      const sonicContract = new ethers.Contract(baseAssetAddress, sonicAbi, signer);
      const address = await signer.getAddress();
      const rawBalance = await sonicContract.balanceOf(address);
      const balance = Number.parseFloat(
        ethers.utils.formatEther(rawBalance)
      ).toFixed(3);
      setSonicBalance(balance);
    };
    const getEarnedTokens = async () => {
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();
      const coreContract = new ethers.Contract(
        coreAddress,
        protocolCoreAbi,
        signer
      );
      const address = await signer.getAddress();
      const rawEarnedAmount = await coreContract.getEarnedSonkTokens(address);
      const earnedAmount = Number.parseFloat(
        ethers.utils.formatEther(rawEarnedAmount)
      ).toFixed(3);
      setEarnedTokens(earnedAmount);
    };
    const getLendingBalance = async () => {
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();
      const coreContract = new ethers.Contract(
        coreAddress,
        protocolCoreAbi,
        signer
      );
      const address = await signer.getAddress();
      const rawAmount = await coreContract.getLendingBalance(address);
      console.log('rawAmount',rawAmount);
      const amount = Number.parseFloat(
        ethers.utils.formatEther(rawAmount)
      ).toFixed(3);
      setLendingBalance(amount);
    };
    const getBorrowBalance = async () => {
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();
      const coreContract = new ethers.Contract(
        coreAddress,
        protocolCoreAbi,
        signer
      );
      const address = await signer.getAddress();
      const rawAmount = await coreContract.getBorrowBalance(address);
      const amount = Number.parseFloat(
        ethers.utils.formatEther(rawAmount)
      ).toFixed(3);
      setBorrowBalance(amount);
    };
    const getCollateralBalance = async () => {
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();
      const coreContract = new ethers.Contract(
        coreAddress,
        protocolCoreAbi,
        signer
      );
      const address = await signer.getAddress();
      const rawAmount = await coreContract.getCollateralBalance(address);
      const amount = Number.parseFloat(
        ethers.utils.formatEther(rawAmount)
      ).toFixed(3);
      setCollateralBalance(amount);
    };
    const getBorrowLimit = async () => {
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();
      const coreContract = new ethers.Contract(
        coreAddress,
        protocolCoreAbi,
        signer
      );
      const address = await signer.getAddress();
      const rawAmount = await coreContract.getBorrowLimit(address);
      const amount = Number.parseFloat(
        ethers.utils.formatEther(rawAmount)
      ).toFixed(3);
      setBorrowLimit(amount);
    };
    const getLiquidationPoint = async () => {
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();
      const coreContract = new ethers.Contract(
        coreAddress,
        protocolCoreAbi,
        signer
      );
      const address = await signer.getAddress();
      const rawAmount = await coreContract.getLiquidationPoint(address);
      const amount = Number.parseFloat(
        ethers.utils.formatEther(rawAmount)
      ).toFixed(3);
      setLiquidationPoint(amount);
    };
    if (isWeb3Enabled && coreAddress) {
      getSonkBalance();
      getSonicBalance();
      getEarnedTokens();
      getLendingBalance();
      getBorrowBalance();
      getCollateralBalance();
      getBorrowLimit();
      getLiquidationPoint();
    }
  }, [isWeb3Enabled, coreAddress, tokenAddress, baseAssetAddress]);

  if (!isWeb3Enabled) {
    return <ErrorSection x={true} />;
  }

  if (!coreAddress) {
    return <ErrorSection x={false} />;
  }

  return (
    <div className="flex w-full min-h-screen font-sans bg-primaryBg">
      <main className="flex flex-col flex-1 gap-6 p-8">
        <header>
          <h1 className="text-3xl font-semibold text-white">Dashboard</h1>
        </header>
        <hr className="border-secondary" />
        <DataSection
          sonkBalance={sonkBalance}
          sonicBalance={sonicBalance}
          earnedTokens={earnedTokens}
          lendingBalance={lendingBalance}
          borrowBalance={borrowBalance}
          collateralBalance={collateralBalance}
        />
        <CollateralSection
          collateralBalance={collateralBalance}
          coreAddress={coreAddress}
          coreAbi={protocolCoreAbi}
          ethAddress={ethAssetAddress}
          ethAbi={ethAbi}
        />
      </main>
      <aside className="flex flex-col gap-y-6 pt-6 pr-6 w-96">
        <ControlSection
          coreAddress={coreAddress}
          coreAbi={protocolCoreAbi}
          sonicAddress={baseAssetAddress}
          sonicAbi={sonicAbi}
        />
        <PositionSection
          borrowLimit={borrowLimit}
          liquidationPoint={liquidationPoint}
        />
      </aside>
    </div>
  );
}
