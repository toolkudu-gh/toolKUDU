import React, { useState, useEffect } from 'react';
import { base44 } from '@/api/base44Client';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Card } from "@/components/ui/card";
import { Textarea } from "@/components/ui/textarea";
import { Calendar } from "@/components/ui/calendar";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { 
  ArrowLeft, MapPin, Clock, User, Sparkles, Calendar as CalendarIcon, 
  Send, Shield, Check, Loader2 
} from 'lucide-react';
import { Link } from 'react-router-dom';
import { createPageUrl } from '@/utils';
import { format, addDays } from 'date-fns';
import { motion } from 'framer-motion';
import { toast } from 'sonner';

const categoryIcons = {
  power_tools: "⚡",
  hand_tools: "🔧",
  garden: "🌿",
  automotive: "🚗",
  painting: "🎨",
  plumbing: "🔩",
  electrical: "💡",
  cleaning: "🧹",
  other: "📦"
};

const conditionStyles = {
  excellent: { bg: "bg-emerald-50", text: "text-emerald-700", border: "border-emerald-200" },
  good: { bg: "bg-amber-50", text: "text-amber-700", border: "border-amber-200" },
  fair: { bg: "bg-stone-50", text: "text-stone-600", border: "border-stone-200" }
};

export default function ToolDetail() {
  const [user, setUser] = useState(null);
  const [message, setMessage] = useState('');
  const [dateRange, setDateRange] = useState({ from: new Date(), to: addDays(new Date(), 3) });
  const queryClient = useQueryClient();

  const urlParams = new URLSearchParams(window.location.search);
  const toolId = urlParams.get('id');

  useEffect(() => {
    base44.auth.me().then(setUser).catch(() => {});
  }, []);

  const { data: tool, isLoading } = useQuery({
    queryKey: ['tool', toolId],
    queryFn: async () => {
      const tools = await base44.entities.Tool.filter({ id: toolId });
      return tools[0];
    },
    enabled: !!toolId
  });

  const requestMutation = useMutation({
    mutationFn: async (data) => {
      await base44.entities.BorrowRequest.create(data);
    },
    onSuccess: () => {
      toast.success('Request sent successfully!');
      setMessage('');
      queryClient.invalidateQueries(['requests']);
    }
  });

  const handleRequest = () => {
    if (!user) {
      base44.auth.redirectToLogin();
      return;
    }

    requestMutation.mutate({
      tool_id: tool.id,
      tool_name: tool.name,
      borrower_name: user.full_name,
      borrower_email: user.email,
      owner_email: tool.owner_email,
      message,
      start_date: dateRange.from ? format(dateRange.from, 'yyyy-MM-dd') : null,
      end_date: dateRange.to ? format(dateRange.to, 'yyyy-MM-dd') : null,
      status: 'pending'
    });
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-stone-50 flex items-center justify-center">
        <Loader2 className="w-8 h-8 animate-spin text-[#6B8E7B]" />
      </div>
    );
  }

  if (!tool) {
    return (
      <div className="min-h-screen bg-stone-50 flex flex-col items-center justify-center p-4">
        <h1 className="text-2xl font-bold text-stone-800 mb-4">Tool not found</h1>
        <Link to={createPageUrl('Home')}>
          <Button variant="outline">
            <ArrowLeft className="w-4 h-4 mr-2" />
            Back to Browse
          </Button>
        </Link>
      </div>
    );
  }

  const condition = conditionStyles[tool.condition] || conditionStyles.good;
  const isOwner = user?.email === tool.owner_email;

  return (
    <div className="min-h-screen bg-gradient-to-b from-stone-50 to-white">
      <div className="max-w-6xl mx-auto px-4 py-8">
        {/* Back Link */}
        <Link 
          to={createPageUrl('Home')}
          className="inline-flex items-center gap-2 text-stone-500 hover:text-stone-700 transition-colors mb-8"
        >
          <ArrowLeft className="w-4 h-4" />
          Back to Browse
        </Link>

        <div className="grid lg:grid-cols-2 gap-10">
          {/* Image Section */}
          <motion.div
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.5 }}
          >
            <div className="relative aspect-square rounded-3xl overflow-hidden bg-gradient-to-br from-stone-100 to-stone-50">
              {tool.image_url ? (
                <img 
                  src={tool.image_url} 
                  alt={tool.name}
                  className="w-full h-full object-cover"
                />
              ) : (
                <div className="w-full h-full flex items-center justify-center text-9xl opacity-30">
                  {categoryIcons[tool.category] || "🔧"}
                </div>
              )}
              
              {/* Availability Badge */}
              <div className="absolute top-6 left-6">
                {tool.availability === 'available' ? (
                  <Badge className="bg-emerald-500/90 text-white backdrop-blur-sm px-4 py-1.5">
                    <Check className="w-3.5 h-3.5 mr-1.5" />
                    Available
                  </Badge>
                ) : (
                  <Badge className="bg-amber-500/90 text-white backdrop-blur-sm px-4 py-1.5">
                    Currently Borrowed
                  </Badge>
                )}
              </div>
            </div>
          </motion.div>

          {/* Details Section */}
          <motion.div
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.5, delay: 0.1 }}
            className="space-y-6"
          >
            {/* Category Badge */}
            <div className="flex items-center gap-2">
              <span className="text-2xl">{categoryIcons[tool.category]}</span>
              <span className="text-stone-500 capitalize">{tool.category?.replace('_', ' ')}</span>
            </div>

            {/* Title */}
            <h1 className="text-3xl md:text-4xl font-bold text-stone-800">{tool.name}</h1>

            {/* Condition & Location */}
            <div className="flex flex-wrap gap-3">
              <Badge 
                variant="outline" 
                className={`${condition.bg} ${condition.text} ${condition.border} border px-3 py-1.5`}
              >
                <Sparkles className="w-3.5 h-3.5 mr-1.5" />
                {tool.condition} condition
              </Badge>
              
              {tool.location && (
                <Badge variant="outline" className="border-stone-200 text-stone-600 px-3 py-1.5">
                  <MapPin className="w-3.5 h-3.5 mr-1.5" />
                  {tool.location}
                </Badge>
              )}
              
              <Badge variant="outline" className="border-stone-200 text-stone-600 px-3 py-1.5">
                <Clock className="w-3.5 h-3.5 mr-1.5" />
                Max {tool.max_borrow_days || 7} days
              </Badge>
            </div>

            {/* Description */}
            {tool.description && (
              <p className="text-stone-600 leading-relaxed text-lg">
                {tool.description}
              </p>
            )}

            {/* Owner Info */}
            <Card className="p-4 bg-stone-50/50 border-0">
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 rounded-full bg-[#6B8E7B]/10 flex items-center justify-center">
                  <User className="w-6 h-6 text-[#6B8E7B]" />
                </div>
                <div>
                  <p className="font-medium text-stone-800">{tool.owner_name || 'Community Member'}</p>
                  <p className="text-sm text-stone-500">Tool Owner</p>
                </div>
              </div>
            </Card>

            {/* Deposit Notice */}
            {tool.deposit_required && (
              <div className="flex items-start gap-3 p-4 rounded-xl bg-amber-50 border border-amber-100">
                <Shield className="w-5 h-5 text-amber-600 mt-0.5" />
                <div>
                  <p className="font-medium text-amber-800">Security Deposit Required</p>
                  <p className="text-sm text-amber-600">The owner may request a deposit before lending</p>
                </div>
              </div>
            )}

            {/* Request Form */}
            {!isOwner && tool.availability === 'available' && (
              <Card className="p-6 bg-white border-stone-100 shadow-sm space-y-4">
                <h3 className="font-semibold text-stone-800 text-lg">Request to Borrow</h3>
                
                {/* Date Picker */}
                <div>
                  <label className="text-sm text-stone-600 mb-2 block">When do you need it?</label>
                  <Popover>
                    <PopoverTrigger asChild>
                      <Button variant="outline" className="w-full justify-start text-left font-normal">
                        <CalendarIcon className="mr-2 h-4 w-4" />
                        {dateRange.from ? (
                          dateRange.to ? (
                            <>
                              {format(dateRange.from, "MMM d")} - {format(dateRange.to, "MMM d, yyyy")}
                            </>
                          ) : (
                            format(dateRange.from, "MMM d, yyyy")
                          )
                        ) : (
                          <span>Pick dates</span>
                        )}
                      </Button>
                    </PopoverTrigger>
                    <PopoverContent className="w-auto p-0" align="start">
                      <Calendar
                        mode="range"
                        selected={dateRange}
                        onSelect={setDateRange}
                        numberOfMonths={1}
                        disabled={(date) => date < new Date()}
                      />
                    </PopoverContent>
                  </Popover>
                </div>

                {/* Message */}
                <div>
                  <label className="text-sm text-stone-600 mb-2 block">Add a message (optional)</label>
                  <Textarea
                    placeholder="Hi! I'd love to borrow this for my project..."
                    value={message}
                    onChange={(e) => setMessage(e.target.value)}
                    className="resize-none"
                    rows={3}
                  />
                </div>

                <Button
                  onClick={handleRequest}
                  disabled={requestMutation.isPending}
                  className="w-full bg-[#6B8E7B] hover:bg-[#5a7a69] text-white py-6 rounded-xl"
                >
                  {requestMutation.isPending ? (
                    <>
                      <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                      Sending...
                    </>
                  ) : (
                    <>
                      <Send className="w-4 h-4 mr-2" />
                      Send Request
                    </>
                  )}
                </Button>
              </Card>
            )}

            {isOwner && (
              <div className="p-4 rounded-xl bg-[#6B8E7B]/5 border border-[#6B8E7B]/10 text-center">
                <p className="text-[#6B8E7B] font-medium">This is your tool</p>
              </div>
            )}
          </motion.div>
        </div>
      </div>
    </div>
  );
}