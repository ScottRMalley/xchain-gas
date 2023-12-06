export const LZ_CHAIN_IDS: Readonly<Record<number, number>> = {
  // Goerli
  5: 10121,

  // BNB testnet
  97: 10102,

  // Avax Fuji
  43113: 10106,

  // Polygon Mumbai
  80001: 10109,

  // Arbitrum goerli
  421613: 10143,

  // Base testnet
  84531: 10160,

  // Sepolia testnet
  11155111: 10161
};

export const LZ_ENDPOINTS: Readonly<Record<string, `0x${string}`>> = {
  "goerli": "0xbfD2135BFfbb0B5378b56643c2Df8a87552Bfa23",
  "bsc-testnet": "0x6Fcb97553D41516Cb228ac03FdC8B9a0a9df04A1",
  "fuji": "0x93f54D755A063cE7bB9e6Ac47Eccc8e33411d706",
  "mumbai": "0xf69186dfBa60DdB133E91E9A4B5673624293d8F8",
  "arbitrum-goerli": "0x6aB5Ae6822647046626e83ee6dB8187151E1d5ab",
  "optimism-goerli": "0xae92d5aD7583AD66E49A0c67BAd18F6ba52dDDc1",
  "fantom-testnet": "0x7dcAD72640F835B0FA36EFD3D6d3ec902C7E5acf",
  "meter-testnet": "0x3De2f3D1Ac59F18159ebCB422322Cb209BA96aAD",
  "zksync-testnet": "0x093D2CF57f764f09C3c2Ac58a42A2601B8C79281"
};