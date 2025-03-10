import React from "react";

const DataSection = ({
  sonkBalance,
  sonicBalance,
  earnedTokens,
  lendingBalance,
  borrowBalance,
  collateralBalance,
}) => {
  return (
    <div className="flex gap-6">
      <div className="flex flex-row justify-evenly p-4 w-1/2 bg-gray-900 rounded-lg gap-y-3">
        <div className="flex flex-col">
          <div className="flex items-center gap-x-3 gap-y-3">
            <div className="text-xs text-secondary font-medium ">Lending</div>
            <span className="text-xs text-white font-medium">100% APY</span>
          </div>
          <div className="text-xl font-semibold text-white">
            {earnedTokens} Sonk
          </div>
          <div className="text-sm tracking-wide text-gray-500">
            {lendingBalance} S
          </div>
        </div>

        <div className="flex flex-col">
          <div className="flex items-center gap-x-3 gap-y-3">
            <div className="text-xs text-primary font-medium ">Borrowing</div>
            <span className="text-xs text-white font-medium">0.3% fee</span>
          </div>
          <div className="text-xl font-semibold text-white">
            {borrowBalance} S
          </div>
          <div className="text-sm tracking-wide text-gray-500">
            {collateralBalance} Ξ
          </div>
        </div>
      </div>

      <div className="flex flex-row justify-evenly p-4 w-1/2 bg-gray-900 rounded-lg gap-y-3">
        <div className="flex flex-col justify-around">
          <div className="flex items-center gap-x-3 gap-y-3">
            <div className="text-xs text-primary font-medium ">
              Sonk Wallet Balance
            </div>
          </div>
          <div className="text-xl font-semibold text-white">
            {sonkBalance} Sonk
          </div>
        </div>
        <div className="flex flex-col justify-around">
          <div className="flex items-center gap-x-3 gap-y-3">
            <div className="text-xs text-secondary font-medium ">
              Sonic Wallet Balance
            </div>
          </div>
          <div className="text-xl font-semibold text-white">
            {sonicBalance} S
          </div>
        </div>
      </div>
    </div>
  );
};

export default DataSection;
