module.exports = (sequelize, DataTypes) => {
  const OtpToken = sequelize.define('OtpToken', {
    email: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    otp: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    expires_at: {
      type: DataTypes.DATE,
      allowNull: false,
    },
    used: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
  });

  return OtpToken;
};
