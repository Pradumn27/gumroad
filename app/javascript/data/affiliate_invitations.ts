import { request } from "$app/utils/request";

export type AffiliateInvitation = {
  id: number;
  seller_name: string;
  seller_id: number;
  invited_by_name: string;
  fee_percent: number;
  apply_to_all_products: boolean;
  destination_url: string | null;
  products: {
    id: string;
    name: string;
    fee_percent: number;
    destination_url: string | null;
  }[];
  created_at: string;
};

export type AffiliateInvitationsData = {
  invitations: AffiliateInvitation[];
};

export const getAffiliateInvitations = (): Promise<AffiliateInvitationsData> =>
  request({ method: "GET", url: "/api/internal/affiliate_invitations", accept: "json" }).then((response) =>
    response.json(),
  );

export const acceptAffiliateInvitation = (invitationId: number): Promise<{ success: boolean; message: string }> =>
  request({ method: "POST", url: `/api/internal/affiliate_invitations/${invitationId}/accept`, accept: "json" }).then(
    (response) => response.json(),
  );

export const rejectAffiliateInvitation = (invitationId: number): Promise<{ success: boolean; message: string }> =>
  request({ method: "POST", url: `/api/internal/affiliate_invitations/${invitationId}/reject`, accept: "json" }).then(
    (response) => response.json(),
  );
