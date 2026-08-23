-- Create machine stock trend view and RPC function
-- This provides time-bucketed stock levels for charting

-- Create the view for machine stock trends
CREATE OR REPLACE VIEW machine_stock_trend_v AS
WITH stock_changes AS (
  SELECT 
    machine_id,
    product_id,
    created_at,
    quantity_change,
    transaction_type,
    -- Calculate running stock level
    SUM(quantity_change) OVER (
      PARTITION BY machine_id, product_id 
      ORDER BY created_at 
      ROWS UNBOUNDED PRECEDING
    ) as running_stock
  FROM stock_transactions
  WHERE transaction_type IN ('restock', 'sale', 'removal', 'adjustment')
),
time_buckets AS (
  SELECT 
    machine_id,
    product_id,
    -- Bucket by hour
    date_trunc('hour', created_at) as ts_hour,
    -- Bucket by day
    date_trunc('day', created_at) as ts_day,
    -- Get the last stock level in each bucket
    LAST_VALUE(running_stock) OVER (
      PARTITION BY machine_id, product_id, date_trunc('hour', created_at)
      ORDER BY created_at
      ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) as stock_units_hour,
    LAST_VALUE(running_stock) OVER (
      PARTITION BY machine_id, product_id, date_trunc('day', created_at)
      ORDER BY created_at
      ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) as stock_units_day,
    -- Check for restock events
    CASE WHEN transaction_type = 'restock' AND quantity_change > 0 THEN quantity_change ELSE NULL END as restock_delta,
    -- Check for sell-out events (stock reaches 0)
    CASE WHEN running_stock <= 0 THEN true ELSE false END as sold_out
  FROM stock_changes
)
SELECT 
  machine_id,
  product_id,
  ts_hour as ts,
  'hour' as bucket_type,
  stock_units_hour as stock_units,
  restock_delta,
  sold_out
FROM time_buckets
WHERE stock_units_hour IS NOT NULL

UNION ALL

SELECT 
  machine_id,
  product_id,
  ts_day as ts,
  'day' as bucket_type,
  stock_units_day as stock_units,
  restock_delta,
  sold_out
FROM time_buckets
WHERE stock_units_day IS NOT NULL;

-- Create RPC function to get machine stock trend data
CREATE OR REPLACE FUNCTION get_machine_stock_trend(
  p_machine_id UUID,
  p_product_id UUID DEFAULT NULL,
  p_category TEXT DEFAULT NULL,
  p_from_ts TIMESTAMPTZ DEFAULT NULL,
  p_to_ts TIMESTAMPTZ DEFAULT NULL,
  p_bucket TEXT DEFAULT 'day'
)
RETURNS TABLE (
  ts TIMESTAMPTZ,
  stock_units INTEGER,
  capacity_units INTEGER,
  product_id UUID,
  product_name TEXT,
  product_category TEXT,
  restock_delta INTEGER,
  sold_out BOOLEAN
) AS $$
BEGIN
  -- Set default time range if not provided
  IF p_from_ts IS NULL THEN
    p_from_ts := NOW() - INTERVAL '30 days';
  END IF;
  
  IF p_to_ts IS NULL THEN
    p_to_ts := NOW();
  END IF;

  RETURN QUERY
  SELECT 
    t.ts,
    t.stock_units,
    mp.par_level as capacity_units,
    t.product_id,
    p.name as product_name,
    p.category as product_category,
    t.restock_delta,
    t.sold_out
  FROM machine_stock_trend_v t
  JOIN products p ON t.product_id = p.id
  LEFT JOIN machine_products mp ON t.machine_id = mp.machine_id AND t.product_id = mp.product_id
  WHERE t.machine_id = p_machine_id
    AND t.bucket_type = p_bucket
    AND t.ts >= p_from_ts
    AND t.ts <= p_to_ts
    AND (p_product_id IS NULL OR t.product_id = p_product_id)
    AND (p_category IS NULL OR p.category = p_category)
  ORDER BY t.ts ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create aggregate function for "All Products" view
CREATE OR REPLACE FUNCTION get_machine_stock_trend_aggregate(
  p_machine_id UUID,
  p_category TEXT DEFAULT NULL,
  p_from_ts TIMESTAMPTZ DEFAULT NULL,
  p_to_ts TIMESTAMPTZ DEFAULT NULL,
  p_bucket TEXT DEFAULT 'day'
)
RETURNS TABLE (
  ts TIMESTAMPTZ,
  total_stock_units INTEGER,
  total_capacity_units INTEGER,
  restock_events INTEGER,
  sold_out_events INTEGER
) AS $$
BEGIN
  -- Set default time range if not provided
  IF p_from_ts IS NULL THEN
    p_from_ts := NOW() - INTERVAL '30 days';
  END IF;
  
  IF p_to_ts IS NULL THEN
    p_to_ts := NOW();
  END IF;

  RETURN QUERY
  SELECT 
    t.ts,
    SUM(t.stock_units) as total_stock_units,
    SUM(COALESCE(mp.par_level, 0)) as total_capacity_units,
    COUNT(t.restock_delta) FILTER (WHERE t.restock_delta IS NOT NULL) as restock_events,
    COUNT(*) FILTER (WHERE t.sold_out) as sold_out_events
  FROM machine_stock_trend_v t
  JOIN products p ON t.product_id = p.id
  LEFT JOIN machine_products mp ON t.machine_id = mp.machine_id AND t.product_id = mp.product_id
  WHERE t.machine_id = p_machine_id
    AND t.bucket_type = p_bucket
    AND t.ts >= p_from_ts
    AND t.ts <= p_to_ts
    AND (p_category IS NULL OR p.category = p_category)
  GROUP BY t.ts
  ORDER BY t.ts ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT SELECT ON machine_stock_trend_v TO authenticated;
GRANT EXECUTE ON FUNCTION get_machine_stock_trend TO authenticated;
GRANT EXECUTE ON FUNCTION get_machine_stock_trend_aggregate TO authenticated;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_stock_transactions_machine_product_time 
ON stock_transactions(machine_id, product_id, created_at);

CREATE INDEX IF NOT EXISTS idx_machine_products_machine_product 
ON machine_products(machine_id, product_id);

CREATE INDEX IF NOT EXISTS idx_products_category 
ON products(category);
