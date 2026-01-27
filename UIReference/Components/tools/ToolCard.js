import React from 'react';
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { MapPin, Clock, Sparkles } from 'lucide-react';
import { motion } from 'framer-motion';
import { Link } from 'react-router-dom';
import { createPageUrl } from '@/utils';

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

const conditionColors = {
  excellent: "bg-emerald-50 text-emerald-700 border-emerald-200",
  good: "bg-amber-50 text-amber-700 border-amber-200",
  fair: "bg-stone-50 text-stone-600 border-stone-200"
};

export default function ToolCard({ tool, index = 0 }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4, delay: index * 0.05 }}
    >
      <Link to={createPageUrl('ToolDetail') + `?id=${tool.id}`}>
        <Card className="group overflow-hidden bg-white border-0 shadow-sm hover:shadow-xl transition-all duration-500 cursor-pointer">
          <div className="relative aspect-[4/3] overflow-hidden bg-gradient-to-br from-stone-100 to-stone-50">
            {tool.image_url ? (
              <img 
                src={tool.image_url} 
                alt={tool.name}
                className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-700"
              />
            ) : (
              <div className="w-full h-full flex items-center justify-center text-6xl opacity-40">
                {categoryIcons[tool.category] || "🔧"}
              </div>
            )}
            
            <div className="absolute top-3 left-3">
              <Badge 
                variant="secondary" 
                className={`${conditionColors[tool.condition]} border backdrop-blur-sm`}
              >
                <Sparkles className="w-3 h-3 mr-1" />
                {tool.condition}
              </Badge>
            </div>

            {tool.availability === 'available' && (
              <div className="absolute top-3 right-3">
                <span className="flex h-3 w-3">
                  <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                  <span className="relative inline-flex rounded-full h-3 w-3 bg-emerald-500"></span>
                </span>
              </div>
            )}
          </div>

          <div className="p-5">
            <div className="flex items-start justify-between gap-2 mb-2">
              <h3 className="font-semibold text-stone-800 text-lg leading-tight group-hover:text-[#6B8E7B] transition-colors">
                {tool.name}
              </h3>
              <span className="text-xl shrink-0">{categoryIcons[tool.category]}</span>
            </div>

            {tool.description && (
              <p className="text-stone-500 text-sm line-clamp-2 mb-4">
                {tool.description}
              </p>
            )}

            <div className="flex items-center justify-between text-xs text-stone-400">
              {tool.location && (
                <span className="flex items-center gap-1">
                  <MapPin className="w-3.5 h-3.5" />
                  {tool.location}
                </span>
              )}
              <span className="flex items-center gap-1">
                <Clock className="w-3.5 h-3.5" />
                Up to {tool.max_borrow_days || 7} days
              </span>
            </div>
          </div>
        </Card>
      </Link>
    </motion.div>
  );
}