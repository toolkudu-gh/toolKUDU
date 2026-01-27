import React, { useState, useEffect } from 'react';
import { base44 } from '@/api/base44Client';
import { useQuery } from '@tanstack/react-query';
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Plus, Search, Wrench, Users, Leaf, ArrowRight } from 'lucide-react';
import { motion } from 'framer-motion';
import ToolCard from '../components/tools/ToolCard';
import CategoryFilter from '../components/tools/CategoryFilter';
import AddToolDialog from '../components/tools/AddToolDialog';
import EmptyState from '../components/ui/EmptyState';

export default function Home() {
  const [user, setUser] = useState(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [showAddDialog, setShowAddDialog] = useState(false);

  useEffect(() => {
    base44.auth.me().then(setUser).catch(() => {});
  }, []);

  const { data: tools = [], isLoading, refetch } = useQuery({
    queryKey: ['tools'],
    queryFn: () => base44.entities.Tool.list('-created_date')
  });

  const filteredTools = tools.filter(tool => {
    const matchesSearch = tool.name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
                         tool.description?.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesCategory = selectedCategory === 'all' || tool.category === selectedCategory;
    return matchesSearch && matchesCategory;
  });

  const availableCount = tools.filter(t => t.availability === 'available').length;

  return (
    <div className="min-h-screen bg-gradient-to-b from-stone-50 to-white">
      {/* Hero Section */}
      <section className="relative overflow-hidden">
        <div className="absolute inset-0 bg-[url('https://images.unsplash.com/photo-1530124566582-a618bc2615dc?w=1920')] bg-cover bg-center opacity-5" />
        <div className="relative max-w-7xl mx-auto px-4 py-20 md:py-32">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="text-center max-w-3xl mx-auto"
          >
            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-[#6B8E7B]/10 text-[#6B8E7B] text-sm font-medium mb-6">
              <Leaf className="w-4 h-4" />
              Sustainable Community Sharing
            </div>
            
            <h1 className="text-4xl md:text-6xl font-bold text-stone-800 tracking-tight mb-6">
              Borrow tools from your{' '}
              <span className="text-[#6B8E7B]">neighbors</span>
            </h1>
            
            <p className="text-lg md:text-xl text-stone-500 mb-10 leading-relaxed">
              Why buy when you can borrow? Join our community of sharers and get access to hundreds of tools for your next project.
            </p>

            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Button
                size="lg"
                onClick={() => setShowAddDialog(true)}
                className="bg-[#6B8E7B] hover:bg-[#5a7a69] text-white px-8 py-6 rounded-xl text-base"
              >
                <Plus className="w-5 h-5 mr-2" />
                Share a Tool
              </Button>
              <Button
                size="lg"
                variant="outline"
                className="border-stone-200 text-stone-700 px-8 py-6 rounded-xl text-base"
                onClick={() => document.getElementById('browse').scrollIntoView({ behavior: 'smooth' })}
              >
                Browse Tools
                <ArrowRight className="w-5 h-5 ml-2" />
              </Button>
            </div>
          </motion.div>

          {/* Stats */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.3, duration: 0.6 }}
            className="flex flex-wrap justify-center gap-8 md:gap-16 mt-16"
          >
            {[
              { icon: Wrench, value: tools.length, label: 'Tools Available' },
              { icon: Users, value: `${new Set(tools.map(t => t.owner_email)).size}+`, label: 'Community Members' },
              { icon: Leaf, value: availableCount, label: 'Ready to Borrow' }
            ].map((stat, i) => (
              <div key={i} className="text-center">
                <div className="flex items-center justify-center gap-2 mb-1">
                  <stat.icon className="w-5 h-5 text-[#6B8E7B]" />
                  <span className="text-3xl md:text-4xl font-bold text-stone-800">{stat.value}</span>
                </div>
                <span className="text-sm text-stone-500">{stat.label}</span>
              </div>
            ))}
          </motion.div>
        </div>
      </section>

      {/* Browse Section */}
      <section id="browse" className="max-w-7xl mx-auto px-4 py-16">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-8">
          <div>
            <h2 className="text-2xl md:text-3xl font-bold text-stone-800">Browse Tools</h2>
            <p className="text-stone-500 mt-1">Find the perfect tool for your project</p>
          </div>
          
          <div className="relative w-full md:w-80">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-stone-400" />
            <Input
              placeholder="Search tools..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-12 py-6 rounded-xl border-stone-200 focus:border-[#6B8E7B] focus:ring-[#6B8E7B]"
            />
          </div>
        </div>

        <div className="mb-8">
          <CategoryFilter selected={selectedCategory} onSelect={setSelectedCategory} />
        </div>

        {isLoading ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {[...Array(8)].map((_, i) => (
              <div key={i} className="animate-pulse">
                <div className="aspect-[4/3] bg-stone-100 rounded-t-2xl" />
                <div className="p-5 bg-white rounded-b-2xl">
                  <div className="h-5 bg-stone-100 rounded mb-2 w-3/4" />
                  <div className="h-4 bg-stone-50 rounded w-full" />
                </div>
              </div>
            ))}
          </div>
        ) : filteredTools.length === 0 ? (
          <EmptyState
            icon={Wrench}
            title="No tools found"
            description={searchQuery || selectedCategory !== 'all' 
              ? "Try adjusting your filters or search query" 
              : "Be the first to share a tool with the community!"
            }
            action={() => setShowAddDialog(true)}
            actionLabel="Share a Tool"
          />
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {filteredTools.map((tool, index) => (
              <ToolCard key={tool.id} tool={tool} index={index} />
            ))}
          </div>
        )}
      </section>

      <AddToolDialog
        open={showAddDialog}
        onOpenChange={setShowAddDialog}
        onSuccess={refetch}
        user={user}
      />
    </div>
  );
}