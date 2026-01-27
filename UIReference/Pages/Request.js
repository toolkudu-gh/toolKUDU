import React, { useState, useEffect } from 'react';
import { base44 } from '@/api/base44Client';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Inbox, Send, Loader2 } from 'lucide-react';
import { motion } from 'framer-motion';
import RequestCard from '../components/requests/RequestCard';
import EmptyState from '../components/ui/EmptyState';
import { toast } from 'sonner';

export default function Requests() {
  const [user, setUser] = useState(null);
  const queryClient = useQueryClient();

  useEffect(() => {
    base44.auth.me().then(setUser).catch(() => {
      base44.auth.redirectToLogin();
    });
  }, []);

  // Incoming requests (where user is the tool owner)
  const { data: incomingRequests = [], isLoading: loadingIncoming } = useQuery({
    queryKey: ['incomingRequests', user?.email],
    queryFn: () => base44.entities.BorrowRequest.filter({ owner_email: user.email }, '-created_date'),
    enabled: !!user?.email
  });

  // Outgoing requests (where user is the borrower)
  const { data: outgoingRequests = [], isLoading: loadingOutgoing } = useQuery({
    queryKey: ['outgoingRequests', user?.email],
    queryFn: () => base44.entities.BorrowRequest.filter({ borrower_email: user.email }, '-created_date'),
    enabled: !!user?.email
  });

  const updateRequestMutation = useMutation({
    mutationFn: ({ id, data }) => base44.entities.BorrowRequest.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries(['incomingRequests']);
      queryClient.invalidateQueries(['outgoingRequests']);
    }
  });

  const updateToolMutation = useMutation({
    mutationFn: ({ id, data }) => base44.entities.Tool.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries(['tools']);
      queryClient.invalidateQueries(['myTools']);
    }
  });

  const handleApprove = async (request) => {
    await updateRequestMutation.mutateAsync({ 
      id: request.id, 
      data: { status: 'approved' } 
    });
    await updateToolMutation.mutateAsync({ 
      id: request.tool_id, 
      data: { availability: 'borrowed' } 
    });
    toast.success('Request approved!');
  };

  const handleDecline = async (request) => {
    await updateRequestMutation.mutateAsync({ 
      id: request.id, 
      data: { status: 'declined' } 
    });
    toast.success('Request declined');
  };

  const handleMarkReturned = async (request) => {
    await updateRequestMutation.mutateAsync({ 
      id: request.id, 
      data: { status: 'returned' } 
    });
    await updateToolMutation.mutateAsync({ 
      id: request.tool_id, 
      data: { availability: 'available' } 
    });
    toast.success('Tool marked as returned');
  };

  const pendingIncoming = incomingRequests.filter(r => r.status === 'pending');
  const pendingOutgoing = outgoingRequests.filter(r => r.status === 'pending');

  if (!user) {
    return (
      <div className="min-h-screen bg-stone-50 flex items-center justify-center">
        <Loader2 className="w-8 h-8 animate-spin text-[#6B8E7B]" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-stone-50 to-white">
      <div className="max-w-4xl mx-auto px-4 py-12">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-stone-800">Borrow Requests</h1>
          <p className="text-stone-500 mt-1">Manage incoming and outgoing requests</p>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-2 gap-4 mb-8">
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            className="bg-white rounded-2xl p-5 border border-stone-100"
          >
            <div className="flex items-center gap-3">
              <div className="p-3 rounded-xl bg-[#6B8E7B]/10">
                <Inbox className="w-5 h-5 text-[#6B8E7B]" />
              </div>
              <div>
                <p className="text-2xl font-bold text-stone-800">{pendingIncoming.length}</p>
                <p className="text-sm text-stone-500">Pending Incoming</p>
              </div>
            </div>
          </motion.div>
          
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="bg-white rounded-2xl p-5 border border-stone-100"
          >
            <div className="flex items-center gap-3">
              <div className="p-3 rounded-xl bg-amber-50">
                <Send className="w-5 h-5 text-amber-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-stone-800">{pendingOutgoing.length}</p>
                <p className="text-sm text-stone-500">Your Pending</p>
              </div>
            </div>
          </motion.div>
        </div>

        {/* Tabs */}
        <Tabs defaultValue="incoming" className="space-y-6">
          <TabsList className="bg-stone-100/50 p-1 w-full">
            <TabsTrigger value="incoming" className="flex-1 rounded-lg">
              <Inbox className="w-4 h-4 mr-2" />
              Incoming ({incomingRequests.length})
            </TabsTrigger>
            <TabsTrigger value="outgoing" className="flex-1 rounded-lg">
              <Send className="w-4 h-4 mr-2" />
              My Requests ({outgoingRequests.length})
            </TabsTrigger>
          </TabsList>

          <TabsContent value="incoming" className="space-y-4">
            {loadingIncoming ? (
              <LoadingSkeleton />
            ) : incomingRequests.length === 0 ? (
              <EmptyState
                icon={Inbox}
                title="No incoming requests"
                description="When someone requests to borrow your tools, you'll see them here"
              />
            ) : (
              incomingRequests.map((request, index) => (
                <RequestCard
                  key={request.id}
                  request={request}
                  type="incoming"
                  onApprove={handleApprove}
                  onDecline={handleDecline}
                  onMarkReturned={handleMarkReturned}
                  index={index}
                />
              ))
            )}
          </TabsContent>

          <TabsContent value="outgoing" className="space-y-4">
            {loadingOutgoing ? (
              <LoadingSkeleton />
            ) : outgoingRequests.length === 0 ? (
              <EmptyState
                icon={Send}
                title="No outgoing requests"
                description="Request to borrow tools and track them here"
              />
            ) : (
              outgoingRequests.map((request, index) => (
                <RequestCard
                  key={request.id}
                  request={request}
                  type="outgoing"
                  index={index}
                />
              ))
            )}
          </TabsContent>
        </Tabs>
      </div>
    </div>
  );
}

function LoadingSkeleton() {
  return (
    <div className="space-y-4">
      {[...Array(3)].map((_, i) => (
        <div key={i} className="bg-white rounded-xl p-5 animate-pulse">
          <div className="flex items-start justify-between">
            <div className="space-y-2">
              <div className="h-5 w-40 bg-stone-100 rounded" />
 