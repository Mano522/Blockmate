const express = require('express');
const router = express.Router();
const multer = require('multer');
const cloudinary = require('cloudinary').v2;
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const Subject = require('../models/Subject');
const Module = require('../models/Module');
const Category = require('../models/Category');

// Cloudinary configuration
cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET
});

const storage = new CloudinaryStorage({
    cloudinary: cloudinary,
    params: {
        folder: 'blockmate-uploads',
        resource_type: 'auto',
        allowed_formats: ['jpg', 'png', 'pdf', 'doc', 'docx', 'webp', 'jpeg'],
        public_id: (req, file) => Date.now() + '-' + file.originalname.split('.')[0]
    }
});

const upload = multer({ storage: storage });

router.post('/subject/:id', upload.single('file'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ message: 'No file uploaded' });
        }

        const subject = await Subject.findById(req.params.id);
        if (!subject) {
            return res.status(404).json({ message: 'Subject not found' });
        }

        const fileData = {
            name: req.body.name || req.file.originalname,
            url: req.file.path, // Cloudinary gives the full URL in path
            public_id: req.file.filename // Store public_id for deletion
        };

        subject.files.push(fileData);
        await subject.save();

        res.status(200).json({
            message: 'File uploaded and attached to subject',
            file: fileData
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// POST upload file and attach to module
router.post('/module/:id', upload.single('file'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ message: 'No file uploaded' });
        }

        const moduleItem = await Module.findById(req.params.id);
        if (!moduleItem) {
            return res.status(404).json({ message: 'Module not found' });
        }

        const fileData = {
            name: req.body.name || req.file.originalname,
            url: req.file.path,
            public_id: req.file.filename
        };

        moduleItem.files.push(fileData);
        await moduleItem.save();

        res.status(200).json({
            message: 'File uploaded and attached to module',
            file: fileData
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// POST upload file and attach to category
router.post('/category/:id', upload.single('file'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ message: 'No file uploaded' });
        }

        const category = await Category.findById(req.params.id);
        if (!category) {
            return res.status(404).json({ message: 'Category not found' });
        }

        const fileData = {
            name: req.body.name || req.file.originalname,
            url: req.file.path,
            public_id: req.file.filename
        };

        category.files = category.files || [];
        category.files.push(fileData);
        await category.save();

        res.status(200).json({
            message: 'File uploaded and attached to category',
            file: fileData
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// POST add external link to subject (unchanged but included for completeness if needed)
router.post('/link/subject/:id', async (req, res) => {
    try {
        const { name, url } = req.body;
        if (!name || !url) return res.status(400).json({ message: 'Name and URL are required' });

        const subject = await Subject.findById(req.params.id);
        if (!subject) return res.status(404).json({ message: 'Subject not found' });

        const fileData = { name, url };
        subject.files.push(fileData);
        await subject.save();

        res.status(200).json({ message: 'Link attached to subject', file: fileData });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// POST add external link to module
router.post('/link/module/:id', async (req, res) => {
    try {
        const { name, url } = req.body;
        if (!name || !url) return res.status(400).json({ message: 'Name and URL are required' });

        const moduleItem = await Module.findById(req.params.id);
        if (!moduleItem) return res.status(404).json({ message: 'Module not found' });

        const fileData = { name, url };
        moduleItem.files.push(fileData);
        await moduleItem.save();

        res.status(200).json({ message: 'Link attached to module', file: fileData });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// DELETE file/link from subject
router.delete('/subject/:id/:fileId', async (req, res) => {
    try {
        const subject = await Subject.findById(req.params.id);
        if (!subject) return res.status(404).json({ message: 'Subject not found' });

        const file = subject.files.id(req.params.fileId);
        if (!file) return res.status(404).json({ message: 'File not found' });

        // Delete from Cloudinary if it's a Cloudinary file
        if (file.public_id) {
            await cloudinary.uploader.destroy(file.public_id);
        }

        subject.files.pull(req.params.fileId);
        await subject.save();

        res.status(200).json({ message: 'File deleted from subject' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// DELETE file/link from module
router.delete('/module/:id/:fileId', async (req, res) => {
    try {
        const moduleItem = await Module.findById(req.params.id);
        if (!moduleItem) return res.status(404).json({ message: 'Module not found' });

        const file = moduleItem.files.id(req.params.fileId);
        if (!file) return res.status(404).json({ message: 'File not found' });

        // Delete from Cloudinary if it's a Cloudinary file
        if (file.public_id) {
            await cloudinary.uploader.destroy(file.public_id);
        }

        moduleItem.files.pull(req.params.fileId);
        await moduleItem.save();

        res.status(200).json({ message: 'File deleted from module' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// DELETE file/link from category
router.delete('/category/:id/:fileId', async (req, res) => {
    try {
        const category = await Category.findById(req.params.id);
        if (!category) return res.status(404).json({ message: 'Category not found' });

        const file = category.files.id(req.params.fileId);
        if (!file) return res.status(404).json({ message: 'File not found' });

        if (file.public_id) {
            await cloudinary.uploader.destroy(file.public_id);
        }

        category.files.pull(req.params.fileId);
        await category.save();

        res.status(200).json({ message: 'File deleted from category' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

module.exports = router;
