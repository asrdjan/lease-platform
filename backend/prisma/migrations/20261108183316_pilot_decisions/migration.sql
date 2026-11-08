-- CreateEnum
CREATE TYPE "CancellationPolicy" AS ENUM ('FLEXIBLE', 'MODERATE', 'STRICT');

-- CreateEnum
CREATE TYPE "DepositStatus" AS ENUM ('NONE', 'HELD', 'RELEASED', 'CAPTURED');

-- AlterTable
ALTER TABLE "Listing" ADD COLUMN     "cancellationPolicy" "CancellationPolicy" NOT NULL DEFAULT 'MODERATE';

-- AlterTable
ALTER TABLE "Order" ADD COLUMN     "cancellationPolicy" "CancellationPolicy" NOT NULL DEFAULT 'MODERATE',
ADD COLUMN     "platformFeeAmount" DECIMAL(10,2) NOT NULL DEFAULT 0,
ALTER COLUMN "currency" SET DEFAULT 'RSD';

-- AlterTable: User.role -> User.roles, keeping each user's existing role
ALTER TABLE "User" ADD COLUMN     "locale" TEXT NOT NULL DEFAULT 'sr-Latn',
ADD COLUMN     "roles" "Role"[] DEFAULT ARRAY['CUSTOMER']::"Role"[];

UPDATE "User" SET "roles" = ARRAY["role"];

ALTER TABLE "User" DROP COLUMN "role";

-- CreateTable
CREATE TABLE "Booking" (
    "id" TEXT NOT NULL,
    "orderId" TEXT NOT NULL,
    "listingId" TEXT NOT NULL,
    "startAt" TIMESTAMP(3) NOT NULL,
    "endAt" TIMESTAMP(3) NOT NULL,
    "isBlocking" BOOLEAN NOT NULL DEFAULT true,
    "depositAmount" DECIMAL(10,2),
    "depositStatus" "DepositStatus" NOT NULL DEFAULT 'NONE',
    "handoverNotes" TEXT,
    "returnNotes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Booking_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Booking_orderId_key" ON "Booking"("orderId");

-- CreateIndex
CREATE UNIQUE INDEX "Order_id_listingId_key" ON "Order"("id", "listingId");

-- CreateIndex
CREATE UNIQUE INDEX "Booking_orderId_listingId_key" ON "Booking"("orderId", "listingId");

-- CreateIndex
CREATE INDEX "Booking_listingId_startAt_idx" ON "Booking"("listingId", "startAt");

-- AddForeignKey
ALTER TABLE "Booking" ADD CONSTRAINT "Booking_orderId_listingId_fkey" FOREIGN KEY ("orderId", "listingId") REFERENCES "Order"("id", "listingId") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Booking" ADD CONSTRAINT "Booking_listingId_fkey" FOREIGN KEY ("listingId") REFERENCES "Listing"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- Booking integrity (not expressible in schema.prisma)
CREATE EXTENSION IF NOT EXISTS btree_gist;

ALTER TABLE "Booking" ADD CONSTRAINT "Booking_valid_range" CHECK ("endAt" > "startAt");

ALTER TABLE "Booking" ADD CONSTRAINT "Booking_no_overlap"
  EXCLUDE USING gist ("listingId" WITH =, tsrange("startAt", "endAt", '[)') WITH &&)
  WHERE ("isBlocking");
