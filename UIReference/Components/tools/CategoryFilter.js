import React from 'react';
import { motion } from 'framer-motion';
import { cn } from '@/lib/utils';

const categories = [
  { id: 'all', label: 'All Tools', icon: '🛠️' },
  { id: 'power_tools', label: 'Power Tools', icon: '⚡' },
  { id: 'hand_tools', label: 'Hand Tools', icon: '🔧' },
  { id: 'garden', label: 'Garden', icon: '🌿' },
  { id: 'automotive', label: 'Automotive', icon: '🚗' },
  { id: 'painting', label: 'Painting', icon: '🎨' },
  { id: 'plumbing', label: 'Plumbing', icon: '🔩' },
  { id: 'electrical', label: 'Electrical', icon: '💡' },
  { id: 'cleaning', label: 'Cleaning', icon: '🧹' },
  { id: 'other', label: 'Other', icon: '📦' }
];

export default function CategoryFilter({ selected, onSelect }) {
  return (
    <div className="flex gap-2 overflow-x-auto pb-2 scrollbar-hide">
      {categories.map((cat) => (
        <motion.button
          key={cat.id}
          onClick={() => onSelect(cat.id)}
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.98 }}
          className={cn(
            "flex items-center gap-2 px-4 py-2.5 rounded-full whitespace-nowrap transition-all duration-300",
            "text-sm font-medium border",
            selected === cat.id
              ? "bg-[#6B8E7B] text-white border-[#6B8E7B] shadow-lg shadow-[#6B8E7B]/20"
              : "bg-white text-stone-600 border-stone-200 hover:border-[#6B8E7B]/30 hover:bg-[#6B8E7B]/5"
          )}
        >
          <span className="text-base">{cat.icon}</span>
          <span>{cat.label}</span>
        </motion.button>
      ))}
    </div>
  );
}