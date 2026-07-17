-- Correctif : permettre à un client d'insérer SES PROPRES notifications
-- (achat, rappel garage, abonnement...), pas seulement l'admin.
-- À exécuter dans Supabase SQL Editor.

drop policy if exists "notifications_insert_admin" on notifications;

create policy "notifications_insert_self_or_admin" on notifications for insert
  with check (client_id = auth.uid() or is_admin());
