import React, { useState, useEffect } from 'react';
import { base44 } from '@/api/base44Client';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Button } from "@/components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Plus, Wrench, Package, Trash2, Edit2, Loader2 } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import ToolCard from '../components/tools/ToolCard';
import AddToolDialog from '../components/tools/AddToolDialog';
import EmptyState from '../components/ui/EmptyState';
import { toast } from 'sonner';
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";

export default function MyTools() {
  const [user, setUser] = useState(null);
  const [showAddDialog, setShowAddDialog] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState(null);
  const queryClient = useQueryClient();

  useEffect(() => {
    base44.auth.me().then(setUser).catch(() => {
      base44.auth.redirectToLogin();
    });
  }, []);

  const { data: myTools = [], isLoading } = useQuery({
    queryKey: ['myTools', user?.email],
    queryFn: () => base44.entities.Tool.filter({ owner_email: user.email }),
    enabled: !!user?.email
  });

  const deleteMutation = useMutation({
    mutationFn: (id) => base44.entities.Tool.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries(['myTools']);
      toast.success('Tool removed');
      setDeleteTarget(null);
    }
  });

  const availableTools = myTools.filter(t => t.availability === 'available');
  const borrowedTools = myTools.filter(t => t.availability === 'borrowed');

  if (!user) {
    return (
      <div className="min-h-screen bg-stone-50 flex items-center justify-center">
        <Loader2 className="w-8 h-8 animate-spin text-[#6B8E7B]" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-stone-50 to-white">
      <div className="max-w-6xl mx-auto px-4 py-12">
        {/* Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-8">
          <div>
            <h1 className="text-3xl font-bold text-stone-800">My Tools</h1>
            <p className="text-stone-500 mt-1">Manage your shared tools</p>
          </div>
          <Button
            onClick={() => setShowAddDialog(true)}
            className="bg-[#6B8E7B] hover:bg-[#5a7a69] text-white"
          >
            <Plus className="w-4 h-4 mr-2" />
            Add New Tool
          </Button>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
          {[
            { label: 'Total Tools', value: myTools.length, icon: Wrench },
            { label: 'Available', value: availableTools.length, icon: Package },
            { label: 'Currently Borrowed', value: borrowedTools.length, icon: Package },
          ].map((stat, i) => (
            <motion.div
              key={i}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.1 }}
              className="bg-white rounded-2xl p-5 border border-stone-100"
            >
              <stat.icon className="w-5 h-5 text-[#6B8E7B] mb-2" />
              <p className="text-2xl font-bold text-stone-800">{stat.value}</p>
              <p className="text-sm text-stone-500">{stat.label}</p>
            </motion.div>
          ))}
        </div>

        {/* Tools Tabs */}
        <Tabs defaultValue="all" className="space-y-6">
          <TabsList className="bg-stone-100/50 p-1">
            <TabsTrigger value="all" className="rounded-lg">All ({myTools.length})</TabsTrigger>
            <TabsTrigger value="available" className="rounded-lg">Available ({availableTools.length})</TabsTrigger>
            <TabsTrigger value="borrowed" className="rounded-lg">Borrowed ({borrowedTools.length})</TabsTrigger>
          </TabsList>

          {isLoading ? (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
              {[...Array(3)].map((_, i) => (
                <div key={i} className="animate-pulse">
                  <div className="aspect-[4/3] bg-stone-100 rounded-t-2xl" />
                  <div className="p-5 bg-white rounded-b-2xl">
                    <div className="h-5 bg-stone-100 rounded mb-2 w-3/4" />
                    <div className="h-4 bg-stone-50 rounded w-full" />
                  </div>
                </div>
              ))}
            </div>
          ) : myTools.length === 0 ? (
            <EmptyState
              icon={Wrench}
              title="No tools yet"
              description="Start sharing tools with your community"
              action={() => setShowAddDialog(true)}
              actionLabel="Share Your First Tool"
            />
          ) : (
            <>
              <TabsContent value="all">
                <ToolGrid tools={myTools} onDelete={setDeleteTarget} />
              </TabsContent>
              <TabsContent value="available">
                <ToolGrid tools={availableTools} onDelete={setDeleteTarget} />
              </TabsContent>
              <TabsContent value="borrowed">
                <ToolGrid tools={borrowedTools} onDelete={setDeleteTarget} />
              </TabsContent>
            </>
          )}
        </Tabs>
      </div>

      <AddToolDialog
        open={showAddDialog}
        onOpenChange={setShowAddDialog}
        onSuccess={() => queryClient.invalidateQueries(['myTools'])}
        user={user}
      />

      {/* Delete Confirmation */}
      <AlertDialog open={!!deleteTarget} onOpenChange={() => setDeleteTarget(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Remove this tool?</AlertDialogTitle>
            <AlertDialogDescription>
              This will permanently remove {deleteTarget?.name} from your shared tools.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction
              onClick={() => deleteMutation.mutate(deleteTarget.id)}
              className="bg-red-500 hover:bg-red-600"
            >
              Remove
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}

function ToolGrid({ tools, onDelete }) {
  if (tools.length === 0) {
    return (
      <div className="text-center py-12 text-stone-500">
        No tools in this category
      </div>
    );
  }

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
      <AnimatePresence>
        {tools.map((tool, index) => (
          <motion.div
            key={tool.id}
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.95 }}
            className="relative group"
          >
            <ToolCard tool={tool} index={index} />
            <button
              onClick={(e) => {
                e.preventDefault();
                onDelete(tool);
              }}
              className="absolute top-4 right-4 p-2 rounded-full bg-white/90 backdrop-blur-sm shadow-sm opacity-0 group-hover:opacity-100 transition-opacity hover:bg-red-50"
            >
              <Trash2 className="w-4 h-4 text-red-500" />
            </button>
          </motion.div>
        ))}
      </AnimatePresence>
    </div>
  );
}