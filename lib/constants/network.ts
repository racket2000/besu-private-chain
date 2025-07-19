export const NETWORK_CONFIG = {
  TLS_PORT: 443,
  HTTP_PORT: 80,
};

export interface CrossAccountPeerConfig {
  /**
   * enode address of the peer node reachable via PrivateLink
   */
  enode: string;
}

export const CROSS_ACCOUNT_PEERS: CrossAccountPeerConfig[] = process.env.CROSS_ACCOUNT_PEERS
  ? process.env.CROSS_ACCOUNT_PEERS.split(',').map((enode) => ({ enode }))
  : [];

export const CROSS_ACCOUNT_P2P_SERVICE_NAMES: string[] =
  process.env.CROSS_ACCOUNT_P2P_SERVICES
    ? process.env.CROSS_ACCOUNT_P2P_SERVICES.split(',').filter((s) => s)
    : [];
