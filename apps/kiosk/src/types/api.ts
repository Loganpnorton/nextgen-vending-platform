export type MachineProduct = {
  id: string;
  product_id: string;
  name: string;
  price: number;
  image_url: string | null;
  category?: string | null;
  slot_position?: string | null;
  stock_level: number;
};

export type CheckinResponse = {
  success: boolean;
  machine_id: string;
  last_ping: string;
  connection_status: "online" | "offline";
  message?: string;
  received_status?: any;
  api_info?: any;
};

export type PairingResponse = {
  machine_id: string;
  machine_code: string;
  machine_token: string;
};

export type PairingLinkResponse = {
  pairing_code: string;
  expires_at: string;
};

export type MachinePairingStatus = {
  machine_id: string;
  machine_token: string;
  machine_code?: string;
} | null;

export type MachineIdentity = {
  machineId?: string;
  machineCode?: string;
  machineToken: string;
  hasIdentity: boolean;
};

export type CartItem = {
  id: string;
  name: string;
  price: number;
  qty: number;
};
