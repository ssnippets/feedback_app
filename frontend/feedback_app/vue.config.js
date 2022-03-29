module.exports = {
    publicPath: process.env.NODE_ENV === 'production'
      ? '/p/static/'
      : '/'
  }