import React from 'react';
import { motion } from 'framer-motion';
import { Button } from "@/components/ui/button";

export default function EmptyState({ 
  icon: Icon, 
  title, 
  description, 
  action, 
  actionLabel 
}) {
  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.95 }}
      animate={{ opacity: 1, scale: 1 }}
      className="flex flex-col items-center justify-center py-16 px-4 text-center"
    >
      {Icon && (
        <div className="w-20 h-20 rounded-3xl bg-gradient-to-br from-stone-100 to-stone-50 flex items-center justify-center mb-6">
          <Icon className="w-10 h-10 text-stone-300" />
        </div>
      )}
      <h3 className="text-xl font-semibold text-stone-700 mb-2">{title}</h3>
      <p className="text-stone-500 max-w-sm mb-6">{description}</p>
      {action && actionLabel && (
        <Button onClick={action} className="bg-[#6B8E7B] hover:bg-[#5a7a69] text-white">
          {actionLabel}
        </Button>
      )}
    </motion.div>
  );
}