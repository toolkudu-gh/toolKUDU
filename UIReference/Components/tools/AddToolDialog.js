import React, { useState } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Switch } from "@/components/ui/switch";
import { base44 } from '@/api/base44Client';
import { Upload, Loader2, Wrench } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

const categories = [
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

export default function AddToolDialog({ open, onOpenChange, onSuccess, user }) {
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    category: '',
    condition: 'good',
    location: '',
    max_borrow_days: 7,
    deposit_required: false
  });
  const [imageFile, setImageFile] = useState(null);
  const [imagePreview, setImagePreview] = useState(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleImageChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setImageFile(file);
      setImagePreview(URL.createObjectURL(file));
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsSubmitting(true);

    let image_url = null;
    if (imageFile) {
      const { file_url } = await base44.integrations.Core.UploadFile({ file: imageFile });
      image_url = file_url;
    }

    await base44.entities.Tool.create({
      ...formData,
      image_url,
      owner_name: user?.full_name || 'Anonymous',
      owner_email: user?.email,
      availability: 'available'
    });

    setIsSubmitting(false);
    setFormData({
      name: '',
      description: '',
      category: '',
      condition: 'good',
      location: '',
      max_borrow_days: 7,
      deposit_required: false
    });
    setImageFile(null);
    setImagePreview(null);
    onSuccess();
    onOpenChange(false);
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-lg max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2 text-xl">
            <div className="p-2 rounded-xl bg-[#6B8E7B]/10">
              <Wrench className="w-5 h-5 text-[#6B8E7B]" />
            </div>
            Share a Tool
          </DialogTitle>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-5 mt-4">
          {/* Image Upload */}
          <div>
            <Label className="text-stone-700 mb-2 block">Tool Photo</Label>
            <label className="cursor-pointer block">
              <div className={`
                relative border-2 border-dashed rounded-2xl overflow-hidden transition-all duration-300
                ${imagePreview ? 'border-[#6B8E7B]' : 'border-stone-200 hover:border-[#6B8E7B]/50'}
              `}>
                {imagePreview ? (
                  <img src={imagePreview} alt="Preview" className="w-full h-48 object-cover" />
                ) : (
                  <div className="h-48 flex flex-col items-center justify-center text-stone-400">
                    <Upload className="w-8 h-8 mb-2" />
                    <span className="text-sm">Click to upload photo</span>
                  </div>
                )}
              </div>
              <input type="file" accept="image/*" onChange={handleImageChange} className="hidden" />
            </label>
          </div>

          {/* Name */}
          <div>
            <Label htmlFor="name" className="text-stone-700">Tool Name *</Label>
            <Input
              id="name"
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              placeholder="e.g., DeWalt Cordless Drill"
              className="mt-1.5"
              required
            />
          </div>

          {/* Category & Condition */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label className="text-stone-700">Category *</Label>
              <Select
                value={formData.category}
                onValueChange={(value) => setFormData({ ...formData, category: value })}
                required
              >
                <SelectTrigger className="mt-1.5">
                  <SelectValue placeholder="Select category" />
                </SelectTrigger>
                <SelectContent>
                  {categories.map((cat) => (
                    <SelectItem key={cat.id} value={cat.id}>
                      <span className="flex items-center gap-2">
                        <span>{cat.icon}</span>
                        <span>{cat.label}</span>
                      </span>
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div>
              <Label className="text-stone-700">Condition</Label>
              <Select
                value={formData.condition}
                onValueChange={(value) => setFormData({ ...formData, condition: value })}
              >
                <SelectTrigger className="mt-1.5">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="excellent">✨ Excellent</SelectItem>
                  <SelectItem value="good">👍 Good</SelectItem>
                  <SelectItem value="fair">👌 Fair</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          {/* Description */}
          <div>
            <Label htmlFor="description" className="text-stone-700">Description</Label>
            <Textarea
              id="description"
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              placeholder="Share any details about the tool..."
              className="mt-1.5 resize-none"
              rows={3}
            />
          </div>

          {/* Location & Max Days */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="location" className="text-stone-700">Your Area</Label>
              <Input
                id="location"
                value={formData.location}
                onChange={(e) => setFormData({ ...formData, location: e.target.value })}
                placeholder="e.g., Downtown"
                className="mt-1.5"
              />
            </div>
            <div>
              <Label htmlFor="max_days" className="text-stone-700">Max Borrow Days</Label>
              <Input
                id="max_days"
                type="number"
                min="1"
                max="30"
                value={formData.max_borrow_days}
                onChange={(e) => setFormData({ ...formData, max_borrow_days: parseInt(e.target.value) || 7 })}
                className="mt-1.5"
              />
            </div>
          </div>

          {/* Deposit */}
          <div className="flex items-center justify-between p-4 rounded-xl bg-stone-50">
            <div>
              <Label className="text-stone-700">Require Deposit?</Label>
              <p className="text-xs text-stone-500 mt-0.5">Optional security for valuable tools</p>
            </div>
            <Switch
              checked={formData.deposit_required}
              onCheckedChange={(checked) => setFormData({ ...formData, deposit_required: checked })}
            />
          </div>

          <Button
            type="submit"
            disabled={isSubmitting || !formData.name || !formData.category}
            className="w-full bg-[#6B8E7B] hover:bg-[#5a7a69] text-white py-6 rounded-xl"
          >
            {isSubmitting ? (
              <>
                <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                Adding Tool...
              </>
            ) : (
              'Share This Tool'
            )}
          </Button>
        </form>
      </DialogContent>
    </Dialog>
  );
}