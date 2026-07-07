-- Script to implement Dual Tickets inside user_tickets table
-- This replaces the original `quantity` colum with `singles_quantity` and `doubles_quantity`.

-- 1. Add new columns
ALTER TABLE public.tickets 
ADD COLUMN IF NOT EXISTS singles_quantity INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS doubles_quantity INT DEFAULT 0;

-- 2. (Optional) Preserve old balances into the new ones 
-- Assuming all old tickets were general, let's copy them to singles
UPDATE public.tickets SET singles_quantity = quantity WHERE quantity > 0;

-- 3. (Optional) Remove the old 'quantity' column to keep it clean.
-- ONLY DO THIS IF NO OTHER SERVICE IS DEPENDENT ON IT. OTHERWISE LEAVE IT.
-- ALTER TABLE public.tickets DROP COLUMN quantity;

-- We also need to add 'match_type' to ticket_transactions so we know which ticket was used/refunded
ALTER TABLE public.ticket_transactions
ADD COLUMN IF NOT EXISTS ticket_type VARCHAR(50);
