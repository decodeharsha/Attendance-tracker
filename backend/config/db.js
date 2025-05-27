const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    const uri = 'mongodb+srv://orishinarayana:rishi2006@cluster0.qd8rzos.mongodb.net/newtest2?retryWrites=true&w=majority';
    console.log('Attempting to connect to MongoDB Atlas...');
    
    await mongoose.connect(uri, {
      serverSelectionTimeoutMS: 60000,
      socketTimeoutMS: 45000,
      maxPoolSize: 10,
      retryWrites: true,
      w: 'majority',
      useNewUrlParser: true,
      useUnifiedTopology: true,
      heartbeatFrequencyMS: 1000,
      connectTimeoutMS: 60000
    });
    console.log('MongoDB Atlas connected successfully');
  } catch (error) {
    console.error('MongoDB connection error:', error);
    process.exit(1);
  }
};

module.exports = connectDB;