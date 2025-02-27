"use client";

import { useEffect, useState } from "react";
import Image from "next/image";
import type { NextPage } from "next";
import { useAccount } from "wagmi";
import { Address } from "~~/components/scaffold-eth";
import { useScaffoldContract, useScaffoldReadContract, useScaffoldWriteContract } from "~~/hooks/scaffold-eth";

const Loogies: NextPage = () => {
  const { address: connectedAddress } = useAccount();
  const [allLoogies, setAllLoogies] = useState<any[]>();
  const [page, setPage] = useState(1n);
  const [loadingLoogies, setLoadingLoogies] = useState(true);
  const perPage = 12n;

  const { data: totalSupply } = useScaffoldReadContract({
    contractName: "WordsFun",
    functionName: "totalSupply",
  });

  const { writeContractAsync } = useScaffoldWriteContract("WordsFun");

  const { data: contract } = useScaffoldContract({
    contractName: "WordsFun",
  });

  useEffect(() => {
    const updateAllLoogies = async () => {
      setLoadingLoogies(true);
      if (contract && totalSupply) {
        console.log("Total Supply: ", totalSupply);
        const collectibleUpdate = [];
        const startIndex = totalSupply - 1n - perPage * (page - 1n);
        for (let tokenIndex = startIndex; tokenIndex > startIndex - perPage && tokenIndex >= 0; tokenIndex--) {
          try {
            const tokenId = await contract.read.tokenByIndex([tokenIndex]);

            console.log('tokenId', tokenId)

            const tokenURI = await contract.read.tokenURI([tokenId]);

            console.log('tokenUR', tokenURI)

            const owner = await contract.read.ownerOf([tokenId]);

            const jsonManifestString = atob(tokenURI.substring(29));

            try {
              const jsonManifest = JSON.parse(jsonManifestString);
              collectibleUpdate.push({ id: tokenId, uri: tokenURI, ...jsonManifest, owner });
            } catch (e) {
              console.log(e);
            }
          } catch (e) {
            console.log(e);
          }
        }
        console.log("Collectible Update: ", collectibleUpdate);
        setAllLoogies(collectibleUpdate);
      }
      setLoadingLoogies(false);
    };
    updateAllLoogies();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [totalSupply, page, perPage, Boolean(contract)]);

  return (
    <>
      <div className="flex items-center flex-col flex-grow pt-10">
        <div className="px-5">
          <h1 className="text-center">
            <span className="block text-4xl font-bold">words.fun</span>
          </h1>
          <div className="text-center max-w-2xl mx-auto">
          An infinite collection of letters, each randomly generated and stored onchain. Mint now to use them in our upcoming play-to-earn Scrabble game.
          </div>
          <div className="flex justify-center items-center mt-6 space-x-2">
            <button
              onClick={async () => {
                try {
                  const token = await writeContractAsync({
                    functionName: "mintNFT",
                    value:  1000000000000000n,
                  });
                  console.log("Minted token", token);
                } catch (e) {
                  console.error(e);
                }
              }}
              className="btn btn-primary"
              disabled={!connectedAddress}
            >
              Mint 1 for 0.001 ETH
            </button>
            <button
              onClick={async () => {
                try {
                  const tokens = await writeContractAsync({
                    functionName: "mintNFTs",
                    args: [2n],
                    value: 11000000000000000n, // 0.011 ETH
                  });
                  console.log("Minted 11 tokens", tokens);
                } catch (e) {
                  console.error(e);
                }
              }}
              className="btn btn-primary"
              disabled={!connectedAddress}
            >
              Mint 11 for 0.011 ETH
            </button>
          </div>
        </div>

        <div className="flex-grow bg-base-900 w-full mt-4 p-8">
          <div className="flex justify-center items-center space-x-2">
            {loadingLoogies ? (
              <p className="my-2 font-medium">Loading...</p>
            ) : !allLoogies?.length ? (
              <p className="my-2 font-medium">No loogies minted</p>
            ) : (
              <div>
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-8 justify-center">
                  {allLoogies.map(loogie => {
                    return (
                      <div
                        key={loogie.id}
                        className="flex flex-col bg-base-300 p-5 text-center items-center max-w-xs rounded-3xl"
                      >
                        <h2 className="text-xl font-bold">{loogie.name}</h2>
                        <Image src={loogie.image} alt={loogie.name} width="300" height="300" />
                        <p>{loogie.description}</p>
                        <Address address={loogie.owner} />
                      </div>
                    );
                  })}
                </div>
                <div className="flex justify-center mt-8">
                  <div className="join">
                    {page > 1n && (
                      <button className="join-item btn" onClick={() => setPage(page - 1n)}>
                        «
                      </button>
                    )}
                    <button className="join-item btn btn-disabled">Page {page.toString()}</button>
                    {totalSupply !== undefined && totalSupply > page * perPage && (
                      <button className="join-item btn" onClick={() => setPage(page + 1n)}>
                        »
                      </button>
                    )}
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </>
  );
};

export default Loogies;