const express = require('express');
const router = express.Router();
const Category = require('../models/Category');
const Module = require('../models/Module');
const Subject = require('../models/Subject');

// GET all categories
router.get('/', async (req, res) => {
    try {
        const { search, subjectId, moduleId } = req.query;
        let query = {};

        if (subjectId) {
            query.subject = subjectId;
        }
        if (moduleId) {
            query.module = moduleId;
        }

        if (search) {
            query.$or = [
                { title: { $regex: search, $options: 'i' } },
                { desc: { $regex: search, $options: 'i' } }
            ];
        }

        const categories = await Category.find(query)
            .populate('subject')
            .populate('module')
            .sort({ createdAt: 1 });
        res.status(200).json(categories);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// GET single category
router.get('/:id', async (req, res) => {
    try {
        const category = await Category.findById(req.params.id)
            .populate('subject')
            .populate('module');
        if (!category) return res.status(404).json({ message: 'Category not found' });
        res.status(200).json(category);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// POST new category
router.post('/', async (req, res) => {
    const { title, desc, subjectId, moduleId, userId } = req.body;

    if (!title || !title.trim()) {
        return res.status(400).json({ message: 'Category title is required' });
    }

    if (!moduleId || !moduleId.trim()) {
        return res.status(400).json({ message: 'Module ID is required for category' });
    }

    try {
        const module = await Module.findById(moduleId);
        if (!module) {
            return res.status(404).json({ message: 'Module not found for this category' });
        }

        if (subjectId && subjectId.trim()) {
            const subject = await Subject.findById(subjectId);
            if (!subject) {
                return res.status(404).json({ message: 'Subject not found for this category' });
            }
        }

        const newCategory = new Category({
            title: title.trim(),
            desc: desc ? desc.trim() : '',
            subject: subjectId || module.subject,
            module: moduleId,
            user: userId || undefined
        });

        const savedCategory = await newCategory.save();
        res.status(201).json(savedCategory);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
});

// PUT update category
router.put('/:id', async (req, res) => {
    try {
        const updatedCategory = await Category.findByIdAndUpdate(
            req.params.id,
            { $set: req.body },
            { new: true, runValidators: true }
        );
        if (!updatedCategory) return res.status(404).json({ message: 'Category not found' });
        res.status(200).json(updatedCategory);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
});

// DELETE category
router.delete('/:id', async (req, res) => {
    try {
        const category = await Category.findByIdAndDelete(req.params.id);
        if (!category) return res.status(404).json({ message: 'Category not found' });
        res.status(200).json({ message: 'Category deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

module.exports = router;
