import * as React from "react";

import {
  getAffiliateInvitations,
  acceptAffiliateInvitation,
  rejectAffiliateInvitation,
  type AffiliateInvitation,
} from "$app/data/affiliate_invitations";

import { Button } from "$app/components/Button";
import { Icon } from "$app/components/Icons";
import { showAlert } from "$app/components/server-components/Alert";

type PendingAffiliateInvitationsProps = {
  onInvitationAction?: () => void;
};

export const PendingAffiliateInvitations: React.FC<PendingAffiliateInvitationsProps> = ({ onInvitationAction }) => {
  const [invitations, setInvitations] = React.useState<AffiliateInvitation[]>([]);
  const [isLoading, setIsLoading] = React.useState(true);
  const [actionLoading, setActionLoading] = React.useState<number | null>(null);

  const loadInvitations = React.useCallback(async () => {
    try {
      setIsLoading(true);
      const data = await getAffiliateInvitations();
      setInvitations(data.invitations);
    } catch (error) {
      console.error("Failed to load affiliate invitations:", error);
      showAlert("Failed to load affiliate invitations", "error");
    } finally {
      setIsLoading(false);
    }
  }, []);

  React.useEffect(() => {
    void loadInvitations();
  }, [loadInvitations]);

  const handleAccept = async (invitation: AffiliateInvitation) => {
    try {
      setActionLoading(invitation.id);
      const result = await acceptAffiliateInvitation(invitation.id);

      if (result.success) {
        showAlert(result.message, "success");
        setInvitations((prev) => prev.filter((inv) => inv.id !== invitation.id));
        onInvitationAction?.();
      } else {
        showAlert(result.message, "error");
      }
    } catch (error) {
      console.error("Failed to accept invitation:", error);
      showAlert("Failed to accept invitation", "error");
    } finally {
      setActionLoading(null);
    }
  };

  const handleReject = async (invitation: AffiliateInvitation) => {
    try {
      setActionLoading(invitation.id);
      const result = await rejectAffiliateInvitation(invitation.id);

      if (result.success) {
        showAlert(result.message, "success");
        setInvitations((prev) => prev.filter((inv) => inv.id !== invitation.id));
        onInvitationAction?.();
      } else {
        showAlert(result.message, "error");
      }
    } catch (error) {
      console.error("Failed to reject invitation:", error);
      showAlert("Failed to reject invitation", "error");
    } finally {
      setActionLoading(null);
    }
  };

  if (isLoading) {
    return (
      <div style={{ display: "flex", justifyContent: "center", padding: "2rem" }}>
        <div>Loading invitations...</div>
      </div>
    );
  }

  if (invitations.length === 0) {
    return null;
  }

  return (
    <div style={{ marginBottom: "2rem" }}>
      <h2 style={{ marginBottom: "0.5rem" }}>Pending affiliate invitations</h2>
      <p style={{ marginBottom: "1.5rem", color: "var(--text-secondary)" }}>
        You have been invited to become an affiliate for these products. Choose to accept or decline each invitation.
      </p>

      <div style={{ overflow: "auto" }}>
        <table style={{ width: "100%", borderCollapse: "collapse" }}>
          <thead>
            <tr style={{ borderBottom: "1px solid var(--border-color)" }}>
              <th style={{ textAlign: "left", padding: "0.75rem", fontWeight: "600" }}>Product</th>
              <th style={{ textAlign: "left", padding: "0.75rem", fontWeight: "600" }}>Seller</th>
              <th style={{ textAlign: "left", padding: "0.75rem", fontWeight: "600" }}>Commission</th>
              <th style={{ textAlign: "left", padding: "0.75rem", fontWeight: "600" }}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {invitations.map((invitation) => (
              <tr key={invitation.id} style={{ borderBottom: "1px solid var(--border-color)" }}>
                <td style={{ padding: "0.75rem" }}>
                  {invitation.products.length === 1 ? (
                    <a
                      href={`/l/${invitation.products[0]?.id}`}
                      target="_blank"
                      rel="noreferrer"
                      style={{ color: "var(--accent-color)", textDecoration: "none" }}
                    >
                      {invitation.products[0]?.name}
                    </a>
                  ) : (
                    <span>{invitation.products.length} products</span>
                  )}
                </td>
                <td style={{ padding: "0.75rem" }}>{invitation.seller_name}</td>
                <td style={{ padding: "0.75rem" }}>
                  {invitation.products.length === 1
                    ? `${invitation.products[0]?.fee_percent}%`
                    : `${invitation.products.map((p) => p.fee_percent).join("%, ")}%`}
                </td>
                <td style={{ padding: "0.75rem" }}>
                  <div style={{ display: "flex", gap: "0.5rem" }}>
                    <Button
                      color="accent"
                      onClick={() => void handleAccept(invitation)}
                      disabled={actionLoading === invitation.id}
                      style={{ display: "flex", alignItems: "center", gap: "0.25rem" }}
                    >
                      <Icon name="check-square" />
                      Accept
                    </Button>
                    <Button
                      onClick={() => void handleReject(invitation)}
                      disabled={actionLoading === invitation.id}
                      style={{ display: "flex", alignItems: "center", gap: "0.25rem" }}
                    >
                      <Icon name="x" />
                      Decline
                    </Button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};
