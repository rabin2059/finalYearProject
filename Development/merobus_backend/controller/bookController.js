const bookSeat = async (req, res) => {
    try {
        const { vehicleId, seatId, userId } = req.body;

        const bookedSeat = await prisma
    } catch (error) {
        
    }
}

module.exports = { bookSeat };