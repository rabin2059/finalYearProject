const prisma = require("../utils/prisma.js");

const changeRole = async (req, res) => {
  const { id, role, licenseNo } = req.body;
  console.log(req.body);

  const user = await prisma.user.findFirst({
    where: {
      id: parseInt(id),
    },
  });

  if (!user) {
    return res.status(404).json({ message: "User not found" });
  }

  if (licenseNo !== user.licenseNo) {
    const updatedUser = await prisma.user.update({
      where: {
        id: parseInt(id),
      },
      data: {
        role: role,
        licenseNo: licenseNo,
      },
    });

    return res
      .status(200)
      .json({ message: "User updated successfully", user: updatedUser });
  }
  
};

const updateUser = async (req, res) => {
  const { id, username, email, phone, address } = req.body;

  const user = await prisma.user.findFirst({
    where: {
      id: parseInt(id),
    },
  });

  if (!user) {
    return res.status(404).json({ message: "User not found" });
  }

  const updatedUser = await prisma.user.update({
    where: { id: parseInt(id) },
    data: { username, email, phone, address },
  });

  return res
    .status(200)
    .json({ message: "User updated successfully", user: updatedUser });
};

module.exports = { changeRole, updateUser };
