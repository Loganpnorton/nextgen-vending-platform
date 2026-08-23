import { useParams } from "react-router-dom";
import Live from "@/pages/Live";

export default function MachineDetail() {
  // For edge-first single-node architecture, machine detail maps to the same live view.
  // We keep the route to preserve the old navigation structure.
  const { machine_id } = useParams<{ machine_id: string }>();
  return <Live key={machine_id} />;
}



