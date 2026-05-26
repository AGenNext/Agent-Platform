import { useEffect, useRef, useState } from "react";
import { getSurrealClient } from "../api/surreal";

export function useLiveQuery<T>(
  sql: string,
  vars?: Record<string, unknown>
): { data: T[]; error: string | null; connected: boolean } {
  const [data, setData] = useState<T[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [connected, setConnected] = useState(false);
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const queryUuidRef = useRef<any>(null);

  useEffect(() => {
    let cancelled = false;

    async function subscribe() {
      try {
        const db = await getSurrealClient();
        if (cancelled) return;

        // Initial fetch
        const initial = await db.query<[T[]]>(sql, vars ?? {});
        if (!cancelled && initial[0]) {
          setData(initial[0]);
        }

        // Live subscription
        const uuid = await db.live(sql, (action, result) => {
          if (cancelled) return;
          setData((prev) => {
            if (action === "CREATE") return [...prev, result as T];
            if (action === "DELETE") {
              const r = result as { id: string };
              return prev.filter((item: unknown) => (item as { id: string }).id !== r.id);
            }
            if (action === "UPDATE") {
              const r = result as T & { id: string };
              return prev.map((item: unknown) =>
                (item as { id: string }).id === r.id ? r : (item as T)
              );
            }
            return prev;
          });
        });

        queryUuidRef.current = uuid;
        setConnected(true);
        setError(null);
      } catch (e) {
        if (!cancelled) {
          setError(String(e));
          setConnected(false);
        }
      }
    }

    subscribe();

    return () => {
      cancelled = true;
      if (queryUuidRef.current) {
        getSurrealClient().then((db) => db.kill(queryUuidRef.current!)).catch(() => {});
      }
    };
  }, [sql]);

  return { data, error, connected };
}
