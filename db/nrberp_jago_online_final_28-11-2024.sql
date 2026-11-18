-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Nov 28, 2024 at 07:40 AM
-- Server version: 10.6.19-MariaDB-cll-lve-log
-- PHP Version: 8.3.14

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `nrberp_jago`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`nrberp`@`localhost` PROCEDURE `sp_CompleteServiceList` (IN `startDate` DATE, IN `endDate` DATE)   BEGIN
    WITH salesService AS (
        SELECT 
            psd.id as psd_id,
            ps.invoice_no AS invoice_no,
        	psd.service_invoice AS service_invoice,
            fa.account_name AS customer_name,
            p.product_name AS product_name,
            psd.service_date AS service_date,
            psd.actual_service_date AS actual_service_date,
            psd.service_number AS service_number,
            psd.service_status AS service_status,
            ps.done_by AS done_by
        FROM 
            product_services AS ps
        JOIN 
            product_service_details AS psd ON ps.id = psd.product_service_id
        JOIN 
            products AS p ON ps.product_id = p.id
        JOIN 
            finance_accounts AS fa ON ps.customer_id = fa.id
        WHERE 
            psd.service_status = 1
        AND
            psd.actual_service_date BETWEEN startDate AND endDate
    )
    SELECT 
        psd_id,
        invoice_no,
        service_invoice,
        customer_name,
        product_name,
        service_date,
        actual_service_date,
        service_number,
        service_status,
        done_by
    FROM 
        salesService
    ORDER BY 
        actual_service_date;
END$$

CREATE DEFINER=`nrberp`@`localhost` PROCEDURE `sp_GeneralLedgerByAccount` (IN `ACCID` INT, IN `CDate1` DATE, IN `CDate2` DATE, IN `PDate1` DATE, IN `PDate2` DATE)   BEGIN

  SELECT
        '' AS `date`,
        company_code AS `company_code`,
        '' AS `voucher_no`,
        '' AS `to_acc_name`,
  CASE
            WHEN (
                COALESCE(
                    (
                        SUM(
                            CASE
                                WHEN balance_type = 'Dr' THEN amount
                                ELSE 0
                            END
                        ) - SUM(
                            CASE
                                WHEN balance_type = 'Cr' THEN amount
                                ELSE 0
                            END
                        )
                    ),
                    0
                ) < 0
            ) THEN (
                COALESCE(
                    (
                        SUM(
                            CASE
                                WHEN balance_type = 'Dr' THEN amount
                                ELSE 0
                            END
                        ) - SUM(
                            CASE
                                WHEN balance_type = 'Cr' THEN amount
                                ELSE 0
                            END
                        )
                    ),
                    0
                ) * -1
            )
            ELSE COALESCE(
                (
                    SUM(
                        CASE
                            WHEN balance_type = 'Dr' THEN amount
                            ELSE 0
                        END
                    ) - SUM(
                        CASE
                            WHEN balance_type = 'Cr' THEN amount
                            ELSE 0
                        END
                    )
                ),
                0
            )
        END  AS amount,
    
    
        CASE
            WHEN (
                COALESCE(
                    (
                        SUM(
                            CASE
                                WHEN balance_type = 'Dr' THEN amount
                                ELSE 0
                            END
                        ) - SUM(
                            CASE
                                WHEN balance_type = 'Cr' THEN amount
                                ELSE 0
                            END
                        )
                    ),
                    0
                ) < 0
            ) THEN 'Cr'
            ELSE 'Dr'
        END AS `balance_type`,
        CONCAT(
            'Opening Balance as on : ',
            DATE_FORMAT(PDate2, '%d-%m-%Y')
        ) AS `narration`,
        '' AS `cheque_no`,
        '' AS `cheque_date`,
        '' AS `cheque_type`,
        '' AS `type`
    FROM
        finance_transactions
    WHERE
        acid = ACCID
        AND voucher_date BETWEEN PDate1 AND PDate2
    GROUP BY
        company_code

    UNION ALL

    SELECT
        DATE_FORMAT(voucher_date, '%d-%m-%Y') AS `Date`,
        company_code AS `company_code`,
        voucher_no AS `voucher_no`,
        to_acc_name AS to_acc_name,
        amount AS `amount`,
        balance_type AS `balance_type`,
        narration AS `narration`,
        cheque_no AS `cheque_no`,
        CASE
            WHEN cheque_date = '0001-01-01' THEN ''
            ELSE DATE_FORMAT(cheque_date, '%d-%m-%Y')
        END AS `cheque_date`,
        cheque_type AS `cheque_type`,
        type AS `type`
    FROM
        finance_transactions 
    WHERE
        acid = ACCID
        AND voucher_date BETWEEN CDate1 AND CDate2;
END$$

CREATE DEFINER=`nrberp`@`localhost` PROCEDURE `sp_GetStockTransferDetailsByInvoice` (IN `invoiceNo` VARCHAR(50))   BEGIN
    SELECT
    	s.id AS stock_id,
        s.stock_date AS stock_date,
        s.invoice_no AS invoice_no,
        s.warehouse_id AS from_warehouse_id,
        s.to_warehouse_id AS to_warehouse_id,
        s.product_id AS product_id,
        fw.name AS from_warehouse_name,
        tw.name AS to_warehouse_name,
        p.product_name AS product_name,
        s.stock_out_quantity AS quantity,
        s.stock_out_unit_price AS unit_price,
        s.stock_out_total_amount AS total_amount,
        s.status AS product_status
    FROM 
        stocks AS s
    JOIN products AS p ON s.product_id = p.id
    JOIN warehouses AS fw ON s.warehouse_id = fw.id
    JOIN warehouses AS tw ON s.to_warehouse_id = tw.id
    WHERE 
        s.invoice_no = invoiceNo;
END$$

CREATE DEFINER=`nrberp`@`localhost` PROCEDURE `sp_GetStockTransferList` (IN `startDate` DATE, IN `endDate` DATE, IN `warehouse_id` INT, IN `status` INT)   BEGIN
    SELECT
        s.stock_date AS stock_date,
        s.invoice_no AS invoice_no,
        fw.name AS from_warehouse_name,
        tw.name AS to_warehouse_name,
        s.status AS status
    FROM 
        stocks AS s
    JOIN products AS p ON s.product_id = p.id
    JOIN warehouses AS fw ON s.warehouse_id = fw.id
    JOIN warehouses AS tw ON s.to_warehouse_id = tw.id
    WHERE 
        (s.warehouse_id = warehouse_id OR s.to_warehouse_id = warehouse_id OR warehouse_id = 0)
        AND s.stock_date BETWEEN startDate AND endDate
        AND s.invoice_no LIKE 'TRN%'
        AND s.status = status
    GROUP BY s.invoice_no;
END$$

CREATE DEFINER=`nrberp`@`localhost` PROCEDURE `sp_GetStockTransferPendingList` (IN `startDate` DATE, IN `endDate` DATE, IN `warehouseId` INT)   BEGIN
    SELECT
        s.stock_date AS stock_date,
        s.invoice_no AS invoice_no,
        fw.name AS from_warehouse_name,
        tw.name AS to_warehouse_name,
        s.status AS status
    FROM 
        stocks AS s
    JOIN products AS p ON s.product_id = p.id
    JOIN warehouses AS fw ON s.warehouse_id = fw.id
    JOIN warehouses AS tw ON s.to_warehouse_id = tw.id
    WHERE 
        (s.warehouse_id = warehouseId OR s.to_warehouse_id = warehouseId OR warehouseId = 0)
        AND s.stock_date BETWEEN startDate AND endDate
        AND s.invoice_no LIKE 'TRN%'
        AND s.status = 0
    GROUP BY 
        s.invoice_no;
END$$

CREATE DEFINER=`nrberp`@`localhost` PROCEDURE `sp_GetTotalSummeryReport` (IN `startDate` DATE, IN `endDate` DATE)   SELECT 
    FORMAT(IFNULL(SUM(s.stock_in_total_amount), 0.00), 2) AS total_purchase_amount,
    FORMAT(IFNULL(SUM(s.stock_out_total_amount), 0.00), 2) AS total_sales_amount,
    FORMAT(
        IFNULL(
            (SELECT SUM(ft.amount) 
             FROM finance_accounts fa
             JOIN finance_transactions ft ON fa.id = ft.acid 
             WHERE fa.account_group_code LIKE '2%' 
               AND fa.id != 13 
               AND ft.voucher_date BETWEEN startDate AND endDate),
            0.00
        ), 2
    ) AS total_expense_amount,
    FORMAT(
        IFNULL(
            (SELECT SUM(TotalValue)
             FROM (
                 SELECT
                    product_id, 
                    stock_in_unit_price AS Price, 
                    (SUM(CASE WHEN stock_date BETWEEN '1900' AND endDate THEN stock_in_quantity ELSE 0 END) 
                     - SUM(CASE WHEN stock_date BETWEEN '1900' AND endDate THEN stock_out_quantity ELSE 0 END)) AS Qty, 
                    (stock_in_unit_price * 
                     (SUM(CASE WHEN stock_date BETWEEN '1900' AND endDate THEN stock_in_quantity ELSE 0 END) 
                      - SUM(CASE WHEN stock_date BETWEEN '1900' AND endDate THEN stock_out_quantity ELSE 0 END))) AS TotalValue
                 FROM stocks
                 GROUP BY product_id, stock_in_unit_price
             ) AS ProductTotals
            ), 0.00
        ), 2
    ) AS current_stock_amount
FROM stocks AS s
WHERE s.stock_date BETWEEN startDate AND endDate$$

CREATE DEFINER=`nrberp`@`localhost` PROCEDURE `sp_GetTotalSummeryReport_old` (IN `startDate` DATE, IN `endDate` DATE)   SELECT 
    FORMAT(IFNULL(SUM(s.stock_in_total_amount), 0.00), 2) AS total_purchase_amount,
    FORMAT(IFNULL(SUM(s.stock_out_total_amount), 0.00), 2) AS total_sales_amount,
    FORMAT(
        IFNULL(
            (SELECT SUM(ft.amount) 
             FROM finance_accounts fa
             JOIN finance_transactions ft ON fa.id = ft.acid 
             WHERE fa.account_group_code LIKE '2%' 
               AND fa.id != 13 
               AND ft.voucher_date BETWEEN startDate AND endDate),
            0.00
        ), 2
    ) AS total_expense_amount,
    FORMAT(
        IFNULL(
            (SELECT SUM(TotalValue)
             FROM (
                 SELECT
                    product_id, 
                    stock_in_unit_price AS Price, 
                    (SUM(CASE WHEN stock_date BETWEEN startDate AND endDate THEN stock_in_quantity ELSE 0 END) 
                     - SUM(CASE WHEN stock_date BETWEEN startDate AND endDate THEN stock_out_quantity ELSE 0 END)) AS Qty, 
                    (stock_in_unit_price * 
                     (SUM(CASE WHEN stock_date BETWEEN startDate AND endDate THEN stock_in_quantity ELSE 0 END) 
                      - SUM(CASE WHEN stock_date BETWEEN startDate AND endDate THEN stock_out_quantity ELSE 0 END))) AS TotalValue
                 FROM stocks
                 GROUP BY product_id, stock_in_unit_price
             ) AS ProductTotals
            ), 0.00
        ), 2
    ) AS current_stock_amount
FROM stocks AS s
WHERE s.stock_date BETWEEN startDate AND endDate$$

CREATE DEFINER=`nrberp`@`localhost` PROCEDURE `sp_PendingServiceList` (IN `startDate` DATE, IN `endDate` DATE)   BEGIN
    WITH salesService AS (
        SELECT 
            psd.id as psd_id,
            ps.invoice_no AS invoice_no,
            fa.account_name AS customer_name,
            p.product_name AS product_name,
            psd.service_date AS service_date,
            psd.service_number AS service_number,
            psd.service_status AS service_status,
            ps.done_by AS done_by
        FROM 
            product_services AS ps
        JOIN 
            product_service_details AS psd ON ps.id = psd.product_service_id
        JOIN 
            products AS p ON ps.product_id = p.id
        JOIN 
            finance_accounts AS fa ON ps.customer_id = fa.id
        WHERE 
            psd.service_status = 0
        AND
            psd.service_date BETWEEN startDate AND endDate
    )
    SELECT 
        psd_id,
        invoice_no,
        customer_name,
        product_name,
        service_date,
        service_number,
        service_status,
        done_by
    FROM 
        salesService
    ORDER BY 
        service_date;
END$$

CREATE DEFINER=`nrberp`@`localhost` PROCEDURE `sp_SalesProfitInvoiceWise` (IN `startDate` DATE, IN `endDate` DATE)   BEGIN
    WITH sales AS (
        SELECT 
            st.invoice_no,
            DATE(MIN(st.stock_date)) AS sales_date,
            SUM(st.stock_out_quantity) AS quantity,
            ROUND(SUM(st.stock_out_quantity * st.purchase_price), 3) AS net_purchase_price,
            ROUND(SUM(st.stock_out_discount), 3) AS net_discount,
            ROUND(SUM(st.stock_out_total_amount), 3) AS net_sales_price,
            ROUND(SUM(st.stock_out_total_amount - (st.stock_out_quantity * st.purchase_price)), 3) AS net_profit
        FROM 
            stocks AS st
        JOIN 
            products AS p ON st.product_id = p.id
        WHERE 
            st.stock_date BETWEEN startDate AND endDate
            AND st.invoice_no LIKE 'INV%'
        GROUP BY 
            st.invoice_no
    )
    
    SELECT 
        invoice_no,
        sales_date,
        quantity,
        net_purchase_price,
        net_discount,
        net_sales_price,
        net_profit
    FROM 
        sales
    ORDER BY 
        invoice_no;
END$$

CREATE DEFINER=`nrberp`@`localhost` PROCEDURE `sp_SalesProfitItemWise` (IN `startDate` DATE, IN `endDate` DATE, IN `givenProductID` INT)   BEGIN
    WITH avg_purchase AS (
        SELECT 
            st.product_id,
            ROUND(SUM(st.stock_in_total_amount) / NULLIF(SUM(st.stock_in_quantity), 0), 3) AS avg_purchase_price
        FROM 
            stocks AS st 
        WHERE 
            st.invoice_no LIKE 'PUR%'
        GROUP BY 
            st.product_id
    ),
    sales AS (
        SELECT 
            st.product_id,
            SUM(st.stock_out_quantity) AS total_sales_quantity,
            SUM(st.stock_out_total_amount) AS total_sales_amount
        FROM 
            stocks AS st
        WHERE 
            st.stock_date BETWEEN startDate AND endDate
            AND (st.product_id = givenProductID OR givenProductID = 0)
            AND st.invoice_no LIKE 'INV%'
        GROUP BY 
            st.product_id
    )
    
    SELECT 
        sa.product_id,
        p.product_name,
        sa.total_sales_quantity,
        ap.avg_purchase_price,
        ROUND((sa.total_sales_quantity * ap.avg_purchase_price), 3) AS total_purchase_amount,
        ROUND((sa.total_sales_amount / NULLIF(sa.total_sales_quantity, 0)), 3) AS avg_sales_price,
        ROUND(sa.total_sales_amount, 3) AS total_sales_amount,
        ROUND((sa.total_sales_amount - (sa.total_sales_quantity * ap.avg_purchase_price)), 3) AS total_profit
    FROM 
        sales AS sa
    JOIN 
        avg_purchase AS ap ON sa.product_id = ap.product_id
    JOIN 
        products AS p ON sa.product_id = p.id;
END$$

CREATE DEFINER=`nrberp`@`localhost` PROCEDURE `sp_StockReportFinishGoodWise` (IN `CDate1` DATE, IN `CDate2` DATE, IN `CWarehouseId` INT, IN `CProductId` INT)   BEGIN
    -- Declare local variables
    DECLARE Date1 DATE;
    DECLARE Date2 DATE;
    DECLARE WarehouseId INT;
    DECLARE ProductId INT;

    -- Assign the procedure parameters to local variables
    SET Date1 = CDate1;
    SET Date2 = CDate2;
    SET WarehouseId = CWarehouseId;
    SET ProductId = CProductId;

    -- Main query to select product stock report with filtering
    SELECT
        products.id,
        products.product_name,
        products.unit_id,
        product_units.unit_name AS unit_id,
        IFNULL(warehouses.name, 'No Warehouse') AS warehouse_name,
        
        -- Calculate the pre-quantity (before Date1) for each warehouse
        IFNULL((
            SELECT
                ROUND(SUM(stocks.stock_in_quantity) - SUM(stocks.stock_out_quantity), 2)
            FROM
                stocks
            WHERE
                stocks.product_id = products.id
                AND (WarehouseId = 0 OR stocks.warehouse_id = WarehouseId)
                AND stocks.warehouse_id = warehouses.id -- Ensure it's specific to the warehouse
                AND DATE(stocks.stock_date) BETWEEN '1900-01-01' AND DATE_SUB(Date1, INTERVAL 1 DAY)
        ), 0) AS PreQty,
        
        -- Calculate the stock-in quantity between Date1 and Date2
        IFNULL((
            SELECT
                ROUND(SUM(stocks.stock_in_quantity), 2)
            FROM
                stocks
            WHERE
                stocks.product_id = products.id
                AND (WarehouseId = 0 OR stocks.warehouse_id = WarehouseId)
                AND stocks.warehouse_id = warehouses.id -- Ensure it's specific to the warehouse
                AND DATE(stocks.stock_date) BETWEEN Date1 AND Date2
        ), 0) AS InQty,
        
        -- Calculate the total stock quantity (PreQty + InQty)
        IFNULL((
            SELECT
                ROUND(SUM(stocks.stock_in_quantity) - SUM(stocks.stock_out_quantity), 2)
            FROM
                stocks
            WHERE
                stocks.product_id = products.id
                AND (WarehouseId = 0 OR stocks.warehouse_id = WarehouseId)
                AND stocks.warehouse_id = warehouses.id -- Ensure it's specific to the warehouse
                AND DATE(stocks.stock_date) BETWEEN '1900-01-01' AND DATE_SUB(Date1, INTERVAL 1 DAY)
        ), 0) + IFNULL((
            SELECT
                ROUND(SUM(stocks.stock_in_quantity), 2)
            FROM
                stocks
            WHERE
                stocks.product_id = products.id
                AND (WarehouseId = 0 OR stocks.warehouse_id = WarehouseId)
                AND stocks.warehouse_id = warehouses.id -- Ensure it's specific to the warehouse
                AND DATE(stocks.stock_date) BETWEEN Date1 AND Date2
        ), 0) AS TotQty,
        
        -- Calculate the stock-out quantity between Date1 and Date2
        IFNULL((
            SELECT
                ROUND(SUM(stocks.stock_out_quantity), 2)
            FROM
                stocks
            WHERE
                stocks.product_id = products.id
                AND (WarehouseId = 0 OR stocks.warehouse_id = WarehouseId)
                AND stocks.warehouse_id = warehouses.id -- Ensure it's specific to the warehouse
                AND DATE(stocks.stock_date) BETWEEN Date1 AND Date2
        ), 0) AS OutQty
    FROM
        products
    LEFT JOIN stocks ON products.id = stocks.product_id
    LEFT JOIN product_units ON product_units.id = products.unit_id
    LEFT JOIN warehouses ON stocks.warehouse_id = warehouses.id
    WHERE
        products.type_id = 1
        AND products.status = 1
        AND (ProductId = 0 OR products.id = ProductId)
        AND (WarehouseId = 0 OR stocks.warehouse_id = WarehouseId)
    GROUP BY
        products.id,
        products.product_name,
        products.unit_id,
        warehouses.id,
        warehouses.name
    ORDER BY
        products.id;

END$$

CREATE DEFINER=`nrberp`@`localhost` PROCEDURE `sp_StockReportItemWise` (IN `CDate1` DATE, IN `CDate2` DATE, IN `CProductID` INT)   BEGIN

    SET @Date1 = CDate1;
    SET @Date2 = CDate2;
    SET @ProductID = CProductID;

    -- Temporary table to store opening balance
    CREATE TEMPORARY TABLE temp_opening_balance AS
    SELECT
        products.id AS product_id,
        IFNULL(SUM(stocks.stock_in_quantity), 0) AS OpeningInQty,
        IFNULL(SUM(stocks.stock_out_quantity), 0) AS OpeningOutQty
    FROM
        products
    LEFT JOIN stocks ON products.id = stocks.product_id
    WHERE
        products.id = @ProductID
        AND date(stocks.stock_date) < @Date1
    GROUP BY
        products.id;

    -- First part: Opening balance
    SELECT
        NULL AS product_id,
        NULL AS product_name,
        NULL AS unit_id,
        NULL AS unit_name,
        NULL AS invoice_no,
        NULL AS stock_date,
        NULL AS InQty,
        NULL AS OutQty,
        IFNULL((
            SELECT
                OpeningInQty - OpeningOutQty
            FROM
                temp_opening_balance
        ), 0) AS OpeningBalance
    UNION ALL
    -- Second part: Current period data
    SELECT
        products.id AS product_id,
        products.product_name,
        products.unit_id,
        product_units.unit_name AS unit_name,
        stocks.invoice_no,
        stocks.stock_date,
        IFNULL(SUM(stocks.stock_in_quantity), 0) AS InQty,
        IFNULL(SUM(stocks.stock_out_quantity), 0) AS OutQty,
        NULL AS OpeningBalance
    FROM
        products
    LEFT JOIN stocks ON products.id = stocks.product_id
    LEFT JOIN product_units ON product_units.id = products.unit_id
    WHERE
        products.id = @ProductID
        AND date(stocks.stock_date) BETWEEN @Date1 AND @Date2
    GROUP BY
        products.id,
        products.product_name,
        products.unit_id,
        product_units.unit_name,
        stocks.invoice_no,
        stocks.stock_date

    -- Ensure the entire result set is ordered by stock_date
    ORDER BY
        stock_date;

    -- Drop the temporary table after use
    DROP TEMPORARY TABLE IF EXISTS temp_opening_balance;

END$$

CREATE DEFINER=`nrberp`@`localhost` PROCEDURE `sp_StockReportMaterialWise` (IN `CDate1` DATE, IN `CDate2` DATE, IN `CWarehouseId` INT, IN `CProductId` INT)   BEGIN
    -- Declare local variables
    DECLARE Date1 DATE;
    DECLARE Date2 DATE;
    DECLARE WarehouseId INT;
    DECLARE ProductId INT;

    -- Assign the procedure parameters to local variables
    SET Date1 = CDate1;
    SET Date2 = CDate2;
    SET WarehouseId = CWarehouseId;
    SET ProductId = CProductId;

    -- Main query to select product stock report with filtering
    SELECT
        products.id,
        products.product_name,
        products.unit_id,
        product_units.unit_name AS unit_id,
        IFNULL(warehouses.name, 'No Warehouse') AS warehouse_name,
        
        -- Calculate the pre-quantity (before Date1) for each warehouse
        IFNULL((
            SELECT
                ROUND(SUM(stocks.stock_in_quantity) - SUM(stocks.stock_out_quantity), 2)
            FROM
                stocks
            WHERE
                stocks.product_id = products.id
                AND (WarehouseId = 0 OR stocks.warehouse_id = WarehouseId)
                AND stocks.warehouse_id = warehouses.id -- Ensure it's specific to the warehouse
                AND DATE(stocks.stock_date) BETWEEN '1900-01-01' AND DATE_SUB(Date1, INTERVAL 1 DAY)
        ), 0) AS PreQty,
        
        -- Calculate the stock-in quantity between Date1 and Date2
        IFNULL((
            SELECT
                ROUND(SUM(stocks.stock_in_quantity), 2)
            FROM
                stocks
            WHERE
                stocks.product_id = products.id
                AND (WarehouseId = 0 OR stocks.warehouse_id = WarehouseId)
                AND stocks.warehouse_id = warehouses.id -- Ensure it's specific to the warehouse
                AND DATE(stocks.stock_date) BETWEEN Date1 AND Date2
        ), 0) AS InQty,
        
        -- Calculate the total stock quantity (PreQty + InQty)
        IFNULL((
            SELECT
                ROUND(SUM(stocks.stock_in_quantity) - SUM(stocks.stock_out_quantity), 2)
            FROM
                stocks
            WHERE
                stocks.product_id = products.id
                AND (WarehouseId = 0 OR stocks.warehouse_id = WarehouseId)
                AND stocks.warehouse_id = warehouses.id -- Ensure it's specific to the warehouse
                AND DATE(stocks.stock_date) BETWEEN '1900-01-01' AND DATE_SUB(Date1, INTERVAL 1 DAY)
        ), 0) + IFNULL((
            SELECT
                ROUND(SUM(stocks.stock_in_quantity), 2)
            FROM
                stocks
            WHERE
                stocks.product_id = products.id
                AND (WarehouseId = 0 OR stocks.warehouse_id = WarehouseId)
                AND stocks.warehouse_id = warehouses.id -- Ensure it's specific to the warehouse
                AND DATE(stocks.stock_date) BETWEEN Date1 AND Date2
        ), 0) AS TotQty,
        
        -- Calculate the stock-out quantity between Date1 and Date2
        IFNULL((
            SELECT
                ROUND(SUM(stocks.stock_out_quantity), 2)
            FROM
                stocks
            WHERE
                stocks.product_id = products.id
                AND (WarehouseId = 0 OR stocks.warehouse_id = WarehouseId)
                AND stocks.warehouse_id = warehouses.id -- Ensure it's specific to the warehouse
                AND DATE(stocks.stock_date) BETWEEN Date1 AND Date2
        ), 0) AS OutQty
    FROM
        products
    LEFT JOIN stocks ON products.id = stocks.product_id
    LEFT JOIN product_units ON product_units.id = products.unit_id
    LEFT JOIN warehouses ON stocks.warehouse_id = warehouses.id
    WHERE
        products.type_id = 2
        AND products.status = 1
        AND (ProductId = 0 OR products.id = ProductId)
        AND (WarehouseId = 0 OR stocks.warehouse_id = WarehouseId)
    GROUP BY
        products.id,
        products.product_name,
        products.unit_id,
        warehouses.id,
        warehouses.name
    ORDER BY
        products.id;

END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `activity_log`
--

CREATE TABLE `activity_log` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `log_name` varchar(255) DEFAULT NULL,
  `description` text NOT NULL,
  `subject_type` varchar(255) DEFAULT NULL,
  `event` varchar(255) DEFAULT NULL,
  `subject_id` bigint(20) UNSIGNED DEFAULT NULL,
  `causer_type` varchar(255) DEFAULT NULL,
  `causer_id` bigint(20) UNSIGNED DEFAULT NULL,
  `properties` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`properties`)),
  `batch_uuid` char(36) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;

--
-- Dumping data for table `activity_log`
--

INSERT INTO `activity_log` (`id`, `log_name`, `description`, `subject_type`, `event`, `subject_id`, `causer_type`, `causer_id`, `properties`, `batch_uuid`, `created_at`, `updated_at`) VALUES
(1, 'default', 'created', 'App\\Models\\User', 'created', 1, NULL, NULL, '{\"attributes\":{\"id\":1,\"first_name\":\"Hipolito\",\"last_name\":\"Aufderhar\",\"email\":\"demo@demo.com\",\"email_verified_at\":\"2023-01-30T11:05:03.000000Z\",\"password\":\"$2y$10$IjQ\\/OJA1sHLz1szIOR8OEu6q4.LcpSAOtoTmQP50U8NSQm\\/n.Hr8.\",\"api_token\":\"$2y$10$va5qgqH3w32oIcZhjZ0j2e6UKQN8X7mm3qr93iDW0aYBMaTZdtCTC\",\"remember_token\":null,\"created_at\":\"2023-01-30T11:05:03.000000Z\",\"updated_at\":\"2023-01-30T11:05:03.000000Z\"}}', NULL, '2023-01-30 05:05:03', '2023-01-30 05:05:03'),
(2, 'default', 'created', 'App\\Models\\UserInfo', 'created', 1, NULL, NULL, '{\"attributes\":{\"id\":1,\"user_id\":1,\"avatar\":null,\"company\":\"Bradtke, Schaden and Greenfelder\",\"phone\":\"(443) 823-0276\",\"website\":\"http:\\/\\/www.stracke.org\\/velit-voluptatem-modi-sit-vel-tenetur\",\"country\":\"CK\",\"language\":\"ik\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:03.000000Z\",\"updated_at\":\"2023-01-30T11:05:03.000000Z\"}}', NULL, '2023-01-30 05:05:03', '2023-01-30 05:05:03'),
(3, 'default', 'created', 'App\\Models\\User', 'created', 2, NULL, NULL, '{\"attributes\":{\"id\":2,\"first_name\":\"Easter\",\"last_name\":\"Rath\",\"email\":\"admin@demo.com\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$1MsuFFDinnOAsROoLuGULukkYyZecQVwndX8I132oq7Ex6PweRotS\",\"api_token\":\"$2y$10$xK9PVEBOAA0wFbQtYv6KougqQQ67xXqYinrAUcwVBJifQud7pGHUa\",\"remember_token\":null,\"created_at\":\"2023-01-30T11:05:04.000000Z\",\"updated_at\":\"2023-01-30T11:05:04.000000Z\"}}', NULL, '2023-01-30 05:05:04', '2023-01-30 05:05:04'),
(4, 'default', 'created', 'App\\Models\\UserInfo', 'created', 2, NULL, NULL, '{\"attributes\":{\"id\":2,\"user_id\":2,\"avatar\":null,\"company\":\"Herman PLC\",\"phone\":\"404-488-8064\",\"website\":\"http:\\/\\/prohaska.com\\/omnis-tempore-eveniet-possimus-explicabo-totam-qui-dolorum\",\"country\":\"AD\",\"language\":\"cy\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:04.000000Z\",\"updated_at\":\"2023-01-30T11:05:04.000000Z\"}}', NULL, '2023-01-30 05:05:04', '2023-01-30 05:05:04'),
(5, 'default', 'created', 'App\\Models\\User', 'created', 3, NULL, NULL, '{\"attributes\":{\"id\":3,\"first_name\":\"Ethan\",\"last_name\":\"Okuneva\",\"email\":\"pmraz@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"mrkayf7HuG\",\"created_at\":\"2023-01-30T11:05:04.000000Z\",\"updated_at\":\"2023-01-30T11:05:04.000000Z\"}}', NULL, '2023-01-30 05:05:04', '2023-01-30 05:05:04'),
(6, 'default', 'created', 'App\\Models\\User', 'created', 4, NULL, NULL, '{\"attributes\":{\"id\":4,\"first_name\":\"Kaley\",\"last_name\":\"Friesen\",\"email\":\"quincy08@example.com\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"TtHHY3OgKO\",\"created_at\":\"2023-01-30T11:05:04.000000Z\",\"updated_at\":\"2023-01-30T11:05:04.000000Z\"}}', NULL, '2023-01-30 05:05:05', '2023-01-30 05:05:05'),
(7, 'default', 'created', 'App\\Models\\User', 'created', 5, NULL, NULL, '{\"attributes\":{\"id\":5,\"first_name\":\"Garret\",\"last_name\":\"Fisher\",\"email\":\"fflatley@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"s3fUCKxKnm\",\"created_at\":\"2023-01-30T11:05:05.000000Z\",\"updated_at\":\"2023-01-30T11:05:05.000000Z\"}}', NULL, '2023-01-30 05:05:05', '2023-01-30 05:05:05'),
(8, 'default', 'created', 'App\\Models\\User', 'created', 6, NULL, NULL, '{\"attributes\":{\"id\":6,\"first_name\":\"Hellen\",\"last_name\":\"Smith\",\"email\":\"kellie.bednar@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"LonPVwhUAo\",\"created_at\":\"2023-01-30T11:05:05.000000Z\",\"updated_at\":\"2023-01-30T11:05:05.000000Z\"}}', NULL, '2023-01-30 05:05:05', '2023-01-30 05:05:05'),
(9, 'default', 'created', 'App\\Models\\User', 'created', 7, NULL, NULL, '{\"attributes\":{\"id\":7,\"first_name\":\"Malinda\",\"last_name\":\"Hahn\",\"email\":\"yazmin23@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"XjogJZvnUg\",\"created_at\":\"2023-01-30T11:05:05.000000Z\",\"updated_at\":\"2023-01-30T11:05:05.000000Z\"}}', NULL, '2023-01-30 05:05:05', '2023-01-30 05:05:05'),
(10, 'default', 'created', 'App\\Models\\User', 'created', 8, NULL, NULL, '{\"attributes\":{\"id\":8,\"first_name\":\"Kim\",\"last_name\":\"Quigley\",\"email\":\"ndubuque@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"HwSwupDWEf\",\"created_at\":\"2023-01-30T11:05:05.000000Z\",\"updated_at\":\"2023-01-30T11:05:05.000000Z\"}}', NULL, '2023-01-30 05:05:05', '2023-01-30 05:05:05'),
(11, 'default', 'created', 'App\\Models\\User', 'created', 9, NULL, NULL, '{\"attributes\":{\"id\":9,\"first_name\":\"Bernadette\",\"last_name\":\"Ritchie\",\"email\":\"monserrat.schinner@example.com\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"mmJmSKhUDq\",\"created_at\":\"2023-01-30T11:05:05.000000Z\",\"updated_at\":\"2023-01-30T11:05:05.000000Z\"}}', NULL, '2023-01-30 05:05:05', '2023-01-30 05:05:05'),
(12, 'default', 'created', 'App\\Models\\User', 'created', 10, NULL, NULL, '{\"attributes\":{\"id\":10,\"first_name\":\"Rory\",\"last_name\":\"Zulauf\",\"email\":\"rice.tate@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"fiqjbkDGQV\",\"created_at\":\"2023-01-30T11:05:05.000000Z\",\"updated_at\":\"2023-01-30T11:05:05.000000Z\"}}', NULL, '2023-01-30 05:05:05', '2023-01-30 05:05:05'),
(13, 'default', 'created', 'App\\Models\\User', 'created', 11, NULL, NULL, '{\"attributes\":{\"id\":11,\"first_name\":\"Gussie\",\"last_name\":\"Hayes\",\"email\":\"senger.timmy@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"UtaKOXLr7g\",\"created_at\":\"2023-01-30T11:05:05.000000Z\",\"updated_at\":\"2023-01-30T11:05:05.000000Z\"}}', NULL, '2023-01-30 05:05:06', '2023-01-30 05:05:06'),
(14, 'default', 'created', 'App\\Models\\User', 'created', 12, NULL, NULL, '{\"attributes\":{\"id\":12,\"first_name\":\"Trystan\",\"last_name\":\"Watsica\",\"email\":\"stacy78@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"3D0OK4iSJd\",\"created_at\":\"2023-01-30T11:05:06.000000Z\",\"updated_at\":\"2023-01-30T11:05:06.000000Z\"}}', NULL, '2023-01-30 05:05:06', '2023-01-30 05:05:06'),
(15, 'default', 'created', 'App\\Models\\User', 'created', 13, NULL, NULL, '{\"attributes\":{\"id\":13,\"first_name\":\"Zola\",\"last_name\":\"Schumm\",\"email\":\"lily.labadie@example.net\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"7gbUeuiIEH\",\"created_at\":\"2023-01-30T11:05:06.000000Z\",\"updated_at\":\"2023-01-30T11:05:06.000000Z\"}}', NULL, '2023-01-30 05:05:06', '2023-01-30 05:05:06'),
(16, 'default', 'created', 'App\\Models\\User', 'created', 14, NULL, NULL, '{\"attributes\":{\"id\":14,\"first_name\":\"Savannah\",\"last_name\":\"Turner\",\"email\":\"kuhic.jayce@example.com\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"vab2Dhe5Va\",\"created_at\":\"2023-01-30T11:05:06.000000Z\",\"updated_at\":\"2023-01-30T11:05:06.000000Z\"}}', NULL, '2023-01-30 05:05:06', '2023-01-30 05:05:06'),
(17, 'default', 'created', 'App\\Models\\User', 'created', 15, NULL, NULL, '{\"attributes\":{\"id\":15,\"first_name\":\"Judge\",\"last_name\":\"Crona\",\"email\":\"geoffrey41@example.net\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"2vNdlvs79Y\",\"created_at\":\"2023-01-30T11:05:06.000000Z\",\"updated_at\":\"2023-01-30T11:05:06.000000Z\"}}', NULL, '2023-01-30 05:05:06', '2023-01-30 05:05:06'),
(18, 'default', 'created', 'App\\Models\\User', 'created', 16, NULL, NULL, '{\"attributes\":{\"id\":16,\"first_name\":\"Angie\",\"last_name\":\"Howell\",\"email\":\"kenny59@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"g5bwoW8BuS\",\"created_at\":\"2023-01-30T11:05:06.000000Z\",\"updated_at\":\"2023-01-30T11:05:06.000000Z\"}}', NULL, '2023-01-30 05:05:06', '2023-01-30 05:05:06'),
(19, 'default', 'created', 'App\\Models\\User', 'created', 17, NULL, NULL, '{\"attributes\":{\"id\":17,\"first_name\":\"Elwin\",\"last_name\":\"Hammes\",\"email\":\"alfredo59@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"VhKET9W8EN\",\"created_at\":\"2023-01-30T11:05:06.000000Z\",\"updated_at\":\"2023-01-30T11:05:06.000000Z\"}}', NULL, '2023-01-30 05:05:06', '2023-01-30 05:05:06'),
(20, 'default', 'created', 'App\\Models\\User', 'created', 18, NULL, NULL, '{\"attributes\":{\"id\":18,\"first_name\":\"Hailie\",\"last_name\":\"Conn\",\"email\":\"jace.quigley@example.net\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"xXaP8P73y3\",\"created_at\":\"2023-01-30T11:05:06.000000Z\",\"updated_at\":\"2023-01-30T11:05:06.000000Z\"}}', NULL, '2023-01-30 05:05:06', '2023-01-30 05:05:06'),
(21, 'default', 'created', 'App\\Models\\User', 'created', 19, NULL, NULL, '{\"attributes\":{\"id\":19,\"first_name\":\"Juwan\",\"last_name\":\"Grimes\",\"email\":\"kohler.norris@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"Wfq3z3tmye\",\"created_at\":\"2023-01-30T11:05:07.000000Z\",\"updated_at\":\"2023-01-30T11:05:07.000000Z\"}}', NULL, '2023-01-30 05:05:07', '2023-01-30 05:05:07'),
(22, 'default', 'created', 'App\\Models\\User', 'created', 20, NULL, NULL, '{\"attributes\":{\"id\":20,\"first_name\":\"Antonetta\",\"last_name\":\"Kirlin\",\"email\":\"harris.rosamond@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"P10us5pot6\",\"created_at\":\"2023-01-30T11:05:07.000000Z\",\"updated_at\":\"2023-01-30T11:05:07.000000Z\"}}', NULL, '2023-01-30 05:05:07', '2023-01-30 05:05:07'),
(23, 'default', 'created', 'App\\Models\\User', 'created', 21, NULL, NULL, '{\"attributes\":{\"id\":21,\"first_name\":\"Green\",\"last_name\":\"Rath\",\"email\":\"umckenzie@example.net\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"gwaUUEQHIv\",\"created_at\":\"2023-01-30T11:05:07.000000Z\",\"updated_at\":\"2023-01-30T11:05:07.000000Z\"}}', NULL, '2023-01-30 05:05:07', '2023-01-30 05:05:07'),
(24, 'default', 'created', 'App\\Models\\User', 'created', 22, NULL, NULL, '{\"attributes\":{\"id\":22,\"first_name\":\"Vincenza\",\"last_name\":\"Von\",\"email\":\"violet.larson@example.net\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"tKkC19a3zp\",\"created_at\":\"2023-01-30T11:05:07.000000Z\",\"updated_at\":\"2023-01-30T11:05:07.000000Z\"}}', NULL, '2023-01-30 05:05:07', '2023-01-30 05:05:07'),
(25, 'default', 'created', 'App\\Models\\User', 'created', 23, NULL, NULL, '{\"attributes\":{\"id\":23,\"first_name\":\"Ladarius\",\"last_name\":\"Schaden\",\"email\":\"ilittel@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"MezWxI1rzd\",\"created_at\":\"2023-01-30T11:05:07.000000Z\",\"updated_at\":\"2023-01-30T11:05:07.000000Z\"}}', NULL, '2023-01-30 05:05:07', '2023-01-30 05:05:07'),
(26, 'default', 'created', 'App\\Models\\User', 'created', 24, NULL, NULL, '{\"attributes\":{\"id\":24,\"first_name\":\"Henriette\",\"last_name\":\"Lowe\",\"email\":\"tcollier@example.net\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"qsC9Tp5NrM\",\"created_at\":\"2023-01-30T11:05:07.000000Z\",\"updated_at\":\"2023-01-30T11:05:07.000000Z\"}}', NULL, '2023-01-30 05:05:07', '2023-01-30 05:05:07'),
(27, 'default', 'created', 'App\\Models\\User', 'created', 25, NULL, NULL, '{\"attributes\":{\"id\":25,\"first_name\":\"Carlee\",\"last_name\":\"Turcotte\",\"email\":\"bogisich.pete@example.net\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"SczBhHe0nJ\",\"created_at\":\"2023-01-30T11:05:07.000000Z\",\"updated_at\":\"2023-01-30T11:05:07.000000Z\"}}', NULL, '2023-01-30 05:05:07', '2023-01-30 05:05:07'),
(28, 'default', 'created', 'App\\Models\\User', 'created', 26, NULL, NULL, '{\"attributes\":{\"id\":26,\"first_name\":\"Felicia\",\"last_name\":\"Sporer\",\"email\":\"eldora13@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"rot02Hiukz\",\"created_at\":\"2023-01-30T11:05:07.000000Z\",\"updated_at\":\"2023-01-30T11:05:07.000000Z\"}}', NULL, '2023-01-30 05:05:07', '2023-01-30 05:05:07'),
(29, 'default', 'created', 'App\\Models\\User', 'created', 27, NULL, NULL, '{\"attributes\":{\"id\":27,\"first_name\":\"Alanna\",\"last_name\":\"Schaefer\",\"email\":\"derrick.beier@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"yup6EMcuEf\",\"created_at\":\"2023-01-30T11:05:07.000000Z\",\"updated_at\":\"2023-01-30T11:05:07.000000Z\"}}', NULL, '2023-01-30 05:05:07', '2023-01-30 05:05:07'),
(30, 'default', 'created', 'App\\Models\\User', 'created', 28, NULL, NULL, '{\"attributes\":{\"id\":28,\"first_name\":\"Christy\",\"last_name\":\"Runolfsson\",\"email\":\"emanuel.walsh@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"IcgX9O2NVn\",\"created_at\":\"2023-01-30T11:05:08.000000Z\",\"updated_at\":\"2023-01-30T11:05:08.000000Z\"}}', NULL, '2023-01-30 05:05:08', '2023-01-30 05:05:08'),
(31, 'default', 'created', 'App\\Models\\User', 'created', 29, NULL, NULL, '{\"attributes\":{\"id\":29,\"first_name\":\"Cecile\",\"last_name\":\"Becker\",\"email\":\"lemke.jadyn@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"nTmZ4goJEv\",\"created_at\":\"2023-01-30T11:05:08.000000Z\",\"updated_at\":\"2023-01-30T11:05:08.000000Z\"}}', NULL, '2023-01-30 05:05:08', '2023-01-30 05:05:08'),
(32, 'default', 'created', 'App\\Models\\User', 'created', 30, NULL, NULL, '{\"attributes\":{\"id\":30,\"first_name\":\"Evan\",\"last_name\":\"Hudson\",\"email\":\"tthompson@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"SE77STcTKC\",\"created_at\":\"2023-01-30T11:05:08.000000Z\",\"updated_at\":\"2023-01-30T11:05:08.000000Z\"}}', NULL, '2023-01-30 05:05:08', '2023-01-30 05:05:08'),
(33, 'default', 'created', 'App\\Models\\User', 'created', 31, NULL, NULL, '{\"attributes\":{\"id\":31,\"first_name\":\"Demarco\",\"last_name\":\"Rath\",\"email\":\"jpfannerstill@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"8NgIfyBQES\",\"created_at\":\"2023-01-30T11:05:08.000000Z\",\"updated_at\":\"2023-01-30T11:05:08.000000Z\"}}', NULL, '2023-01-30 05:05:08', '2023-01-30 05:05:08'),
(34, 'default', 'created', 'App\\Models\\User', 'created', 32, NULL, NULL, '{\"attributes\":{\"id\":32,\"first_name\":\"Napoleon\",\"last_name\":\"Pollich\",\"email\":\"vallie.dubuque@example.net\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"EZoVRtkUCp\",\"created_at\":\"2023-01-30T11:05:08.000000Z\",\"updated_at\":\"2023-01-30T11:05:08.000000Z\"}}', NULL, '2023-01-30 05:05:08', '2023-01-30 05:05:08'),
(35, 'default', 'created', 'App\\Models\\User', 'created', 33, NULL, NULL, '{\"attributes\":{\"id\":33,\"first_name\":\"Hilbert\",\"last_name\":\"Lynch\",\"email\":\"golda93@example.net\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"RXAvhRqi4X\",\"created_at\":\"2023-01-30T11:05:08.000000Z\",\"updated_at\":\"2023-01-30T11:05:08.000000Z\"}}', NULL, '2023-01-30 05:05:08', '2023-01-30 05:05:08'),
(36, 'default', 'created', 'App\\Models\\User', 'created', 34, NULL, NULL, '{\"attributes\":{\"id\":34,\"first_name\":\"Melany\",\"last_name\":\"Kuvalis\",\"email\":\"krystel25@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"qpUFG2DM4p\",\"created_at\":\"2023-01-30T11:05:08.000000Z\",\"updated_at\":\"2023-01-30T11:05:08.000000Z\"}}', NULL, '2023-01-30 05:05:08', '2023-01-30 05:05:08'),
(37, 'default', 'created', 'App\\Models\\User', 'created', 35, NULL, NULL, '{\"attributes\":{\"id\":35,\"first_name\":\"Marlee\",\"last_name\":\"Cormier\",\"email\":\"nadia.heller@example.com\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"PFEyDUjXgV\",\"created_at\":\"2023-01-30T11:05:08.000000Z\",\"updated_at\":\"2023-01-30T11:05:08.000000Z\"}}', NULL, '2023-01-30 05:05:08', '2023-01-30 05:05:08'),
(38, 'default', 'created', 'App\\Models\\User', 'created', 36, NULL, NULL, '{\"attributes\":{\"id\":36,\"first_name\":\"Jayden\",\"last_name\":\"Schoen\",\"email\":\"america.purdy@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"9poiXp5qbD\",\"created_at\":\"2023-01-30T11:05:08.000000Z\",\"updated_at\":\"2023-01-30T11:05:08.000000Z\"}}', NULL, '2023-01-30 05:05:08', '2023-01-30 05:05:08'),
(39, 'default', 'created', 'App\\Models\\User', 'created', 37, NULL, NULL, '{\"attributes\":{\"id\":37,\"first_name\":\"Alene\",\"last_name\":\"Mueller\",\"email\":\"pshields@example.net\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"k11ebpE9oG\",\"created_at\":\"2023-01-30T11:05:09.000000Z\",\"updated_at\":\"2023-01-30T11:05:09.000000Z\"}}', NULL, '2023-01-30 05:05:09', '2023-01-30 05:05:09'),
(40, 'default', 'created', 'App\\Models\\User', 'created', 38, NULL, NULL, '{\"attributes\":{\"id\":38,\"first_name\":\"Obie\",\"last_name\":\"Crist\",\"email\":\"dare.queenie@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"ysGN2Yg4FW\",\"created_at\":\"2023-01-30T11:05:09.000000Z\",\"updated_at\":\"2023-01-30T11:05:09.000000Z\"}}', NULL, '2023-01-30 05:05:09', '2023-01-30 05:05:09'),
(41, 'default', 'created', 'App\\Models\\User', 'created', 39, NULL, NULL, '{\"attributes\":{\"id\":39,\"first_name\":\"Flossie\",\"last_name\":\"Collins\",\"email\":\"huel.grant@example.com\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"xV3VQ6HkgJ\",\"created_at\":\"2023-01-30T11:05:09.000000Z\",\"updated_at\":\"2023-01-30T11:05:09.000000Z\"}}', NULL, '2023-01-30 05:05:09', '2023-01-30 05:05:09'),
(42, 'default', 'created', 'App\\Models\\User', 'created', 40, NULL, NULL, '{\"attributes\":{\"id\":40,\"first_name\":\"Chasity\",\"last_name\":\"Ondricka\",\"email\":\"courtney65@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"lYYqHfhOAN\",\"created_at\":\"2023-01-30T11:05:09.000000Z\",\"updated_at\":\"2023-01-30T11:05:09.000000Z\"}}', NULL, '2023-01-30 05:05:09', '2023-01-30 05:05:09'),
(43, 'default', 'created', 'App\\Models\\User', 'created', 41, NULL, NULL, '{\"attributes\":{\"id\":41,\"first_name\":\"Gerry\",\"last_name\":\"Cummings\",\"email\":\"jarod.stanton@example.com\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"fNB77b2MoO\",\"created_at\":\"2023-01-30T11:05:09.000000Z\",\"updated_at\":\"2023-01-30T11:05:09.000000Z\"}}', NULL, '2023-01-30 05:05:09', '2023-01-30 05:05:09'),
(44, 'default', 'created', 'App\\Models\\User', 'created', 42, NULL, NULL, '{\"attributes\":{\"id\":42,\"first_name\":\"Ian\",\"last_name\":\"Walker\",\"email\":\"reichel.ford@example.net\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"zq1TGXCRdt\",\"created_at\":\"2023-01-30T11:05:09.000000Z\",\"updated_at\":\"2023-01-30T11:05:09.000000Z\"}}', NULL, '2023-01-30 05:05:09', '2023-01-30 05:05:09'),
(45, 'default', 'created', 'App\\Models\\User', 'created', 43, NULL, NULL, '{\"attributes\":{\"id\":43,\"first_name\":\"Moses\",\"last_name\":\"Ritchie\",\"email\":\"wunsch.lynn@example.com\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"t9zkKOM4WJ\",\"created_at\":\"2023-01-30T11:05:09.000000Z\",\"updated_at\":\"2023-01-30T11:05:09.000000Z\"}}', NULL, '2023-01-30 05:05:09', '2023-01-30 05:05:09'),
(46, 'default', 'created', 'App\\Models\\User', 'created', 44, NULL, NULL, '{\"attributes\":{\"id\":44,\"first_name\":\"Fern\",\"last_name\":\"McDermott\",\"email\":\"murazik.rosemary@example.net\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"KrbuSUD1XQ\",\"created_at\":\"2023-01-30T11:05:09.000000Z\",\"updated_at\":\"2023-01-30T11:05:09.000000Z\"}}', NULL, '2023-01-30 05:05:10', '2023-01-30 05:05:10'),
(47, 'default', 'created', 'App\\Models\\User', 'created', 45, NULL, NULL, '{\"attributes\":{\"id\":45,\"first_name\":\"Amani\",\"last_name\":\"West\",\"email\":\"hbernhard@example.net\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"1xL6mQN7FO\",\"created_at\":\"2023-01-30T11:05:10.000000Z\",\"updated_at\":\"2023-01-30T11:05:10.000000Z\"}}', NULL, '2023-01-30 05:05:10', '2023-01-30 05:05:10'),
(48, 'default', 'created', 'App\\Models\\User', 'created', 46, NULL, NULL, '{\"attributes\":{\"id\":46,\"first_name\":\"Leta\",\"last_name\":\"O\'Reilly\",\"email\":\"leora59@example.com\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"TU5fpNB9Nb\",\"created_at\":\"2023-01-30T11:05:10.000000Z\",\"updated_at\":\"2023-01-30T11:05:10.000000Z\"}}', NULL, '2023-01-30 05:05:10', '2023-01-30 05:05:10'),
(49, 'default', 'created', 'App\\Models\\User', 'created', 47, NULL, NULL, '{\"attributes\":{\"id\":47,\"first_name\":\"Hilda\",\"last_name\":\"Erdman\",\"email\":\"oswaldo.mann@example.com\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"xXNp2FmCOo\",\"created_at\":\"2023-01-30T11:05:10.000000Z\",\"updated_at\":\"2023-01-30T11:05:10.000000Z\"}}', NULL, '2023-01-30 05:05:10', '2023-01-30 05:05:10'),
(50, 'default', 'created', 'App\\Models\\User', 'created', 48, NULL, NULL, '{\"attributes\":{\"id\":48,\"first_name\":\"Deborah\",\"last_name\":\"Considine\",\"email\":\"auer.stephanie@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"alDAhYCNuu\",\"created_at\":\"2023-01-30T11:05:10.000000Z\",\"updated_at\":\"2023-01-30T11:05:10.000000Z\"}}', NULL, '2023-01-30 05:05:10', '2023-01-30 05:05:10'),
(51, 'default', 'created', 'App\\Models\\User', 'created', 49, NULL, NULL, '{\"attributes\":{\"id\":49,\"first_name\":\"Garnett\",\"last_name\":\"Wiegand\",\"email\":\"bryce.denesik@example.com\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"tNNJfEkqMK\",\"created_at\":\"2023-01-30T11:05:11.000000Z\",\"updated_at\":\"2023-01-30T11:05:11.000000Z\"}}', NULL, '2023-01-30 05:05:11', '2023-01-30 05:05:11'),
(52, 'default', 'created', 'App\\Models\\User', 'created', 50, NULL, NULL, '{\"attributes\":{\"id\":50,\"first_name\":\"Roscoe\",\"last_name\":\"Feeney\",\"email\":\"wpadberg@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"kpe5IiXSVa\",\"created_at\":\"2023-01-30T11:05:11.000000Z\",\"updated_at\":\"2023-01-30T11:05:11.000000Z\"}}', NULL, '2023-01-30 05:05:11', '2023-01-30 05:05:11'),
(53, 'default', 'created', 'App\\Models\\User', 'created', 51, NULL, NULL, '{\"attributes\":{\"id\":51,\"first_name\":\"Naomie\",\"last_name\":\"Watsica\",\"email\":\"tleuschke@example.com\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"sWw2mC4a2S\",\"created_at\":\"2023-01-30T11:05:11.000000Z\",\"updated_at\":\"2023-01-30T11:05:11.000000Z\"}}', NULL, '2023-01-30 05:05:11', '2023-01-30 05:05:11'),
(54, 'default', 'created', 'App\\Models\\User', 'created', 52, NULL, NULL, '{\"attributes\":{\"id\":52,\"first_name\":\"Mercedes\",\"last_name\":\"Dickinson\",\"email\":\"cory.upton@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"qeOebkITj7\",\"created_at\":\"2023-01-30T11:05:11.000000Z\",\"updated_at\":\"2023-01-30T11:05:11.000000Z\"}}', NULL, '2023-01-30 05:05:11', '2023-01-30 05:05:11'),
(55, 'default', 'created', 'App\\Models\\User', 'created', 53, NULL, NULL, '{\"attributes\":{\"id\":53,\"first_name\":\"Kieran\",\"last_name\":\"Kemmer\",\"email\":\"andy.cummerata@example.net\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"I3drbkDH4I\",\"created_at\":\"2023-01-30T11:05:11.000000Z\",\"updated_at\":\"2023-01-30T11:05:11.000000Z\"}}', NULL, '2023-01-30 05:05:11', '2023-01-30 05:05:11'),
(56, 'default', 'created', 'App\\Models\\User', 'created', 54, NULL, NULL, '{\"attributes\":{\"id\":54,\"first_name\":\"Rhea\",\"last_name\":\"Dickinson\",\"email\":\"swaniawski.griffin@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"WH6pX1HwR6\",\"created_at\":\"2023-01-30T11:05:11.000000Z\",\"updated_at\":\"2023-01-30T11:05:11.000000Z\"}}', NULL, '2023-01-30 05:05:11', '2023-01-30 05:05:11'),
(57, 'default', 'created', 'App\\Models\\User', 'created', 55, NULL, NULL, '{\"attributes\":{\"id\":55,\"first_name\":\"Hazel\",\"last_name\":\"Cronin\",\"email\":\"rutherford.kacie@example.net\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"9ULw9zXY2I\",\"created_at\":\"2023-01-30T11:05:11.000000Z\",\"updated_at\":\"2023-01-30T11:05:11.000000Z\"}}', NULL, '2023-01-30 05:05:12', '2023-01-30 05:05:12'),
(58, 'default', 'created', 'App\\Models\\User', 'created', 56, NULL, NULL, '{\"attributes\":{\"id\":56,\"first_name\":\"Maiya\",\"last_name\":\"Heidenreich\",\"email\":\"thaddeus59@example.com\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"krgAteBVIN\",\"created_at\":\"2023-01-30T11:05:12.000000Z\",\"updated_at\":\"2023-01-30T11:05:12.000000Z\"}}', NULL, '2023-01-30 05:05:12', '2023-01-30 05:05:12'),
(59, 'default', 'created', 'App\\Models\\User', 'created', 57, NULL, NULL, '{\"attributes\":{\"id\":57,\"first_name\":\"Winnifred\",\"last_name\":\"Bartoletti\",\"email\":\"garry05@example.com\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"aIxomeVwSJ\",\"created_at\":\"2023-01-30T11:05:12.000000Z\",\"updated_at\":\"2023-01-30T11:05:12.000000Z\"}}', NULL, '2023-01-30 05:05:12', '2023-01-30 05:05:12'),
(60, 'default', 'created', 'App\\Models\\User', 'created', 58, NULL, NULL, '{\"attributes\":{\"id\":58,\"first_name\":\"Sarina\",\"last_name\":\"Herman\",\"email\":\"layne.jacobi@example.com\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"3TuPDrdjpi\",\"created_at\":\"2023-01-30T11:05:12.000000Z\",\"updated_at\":\"2023-01-30T11:05:12.000000Z\"}}', NULL, '2023-01-30 05:05:12', '2023-01-30 05:05:12'),
(61, 'default', 'created', 'App\\Models\\User', 'created', 59, NULL, NULL, '{\"attributes\":{\"id\":59,\"first_name\":\"Hallie\",\"last_name\":\"Jerde\",\"email\":\"hprohaska@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"S4lM8Z5lhU\",\"created_at\":\"2023-01-30T11:05:12.000000Z\",\"updated_at\":\"2023-01-30T11:05:12.000000Z\"}}', NULL, '2023-01-30 05:05:12', '2023-01-30 05:05:12'),
(62, 'default', 'created', 'App\\Models\\User', 'created', 60, NULL, NULL, '{\"attributes\":{\"id\":60,\"first_name\":\"Kailyn\",\"last_name\":\"West\",\"email\":\"mhammes@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"nv9ONrYWsc\",\"created_at\":\"2023-01-30T11:05:12.000000Z\",\"updated_at\":\"2023-01-30T11:05:12.000000Z\"}}', NULL, '2023-01-30 05:05:12', '2023-01-30 05:05:12'),
(63, 'default', 'created', 'App\\Models\\User', 'created', 61, NULL, NULL, '{\"attributes\":{\"id\":61,\"first_name\":\"Morris\",\"last_name\":\"Denesik\",\"email\":\"junius01@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"xVm5v9SPeb\",\"created_at\":\"2023-01-30T11:05:12.000000Z\",\"updated_at\":\"2023-01-30T11:05:12.000000Z\"}}', NULL, '2023-01-30 05:05:13', '2023-01-30 05:05:13'),
(64, 'default', 'created', 'App\\Models\\User', 'created', 62, NULL, NULL, '{\"attributes\":{\"id\":62,\"first_name\":\"Cielo\",\"last_name\":\"Smitham\",\"email\":\"derek.mohr@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"OmitnGORr4\",\"created_at\":\"2023-01-30T11:05:13.000000Z\",\"updated_at\":\"2023-01-30T11:05:13.000000Z\"}}', NULL, '2023-01-30 05:05:13', '2023-01-30 05:05:13'),
(65, 'default', 'created', 'App\\Models\\User', 'created', 63, NULL, NULL, '{\"attributes\":{\"id\":63,\"first_name\":\"Shirley\",\"last_name\":\"Nader\",\"email\":\"serenity35@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"KEeYzIfshy\",\"created_at\":\"2023-01-30T11:05:13.000000Z\",\"updated_at\":\"2023-01-30T11:05:13.000000Z\"}}', NULL, '2023-01-30 05:05:13', '2023-01-30 05:05:13'),
(66, 'default', 'created', 'App\\Models\\User', 'created', 64, NULL, NULL, '{\"attributes\":{\"id\":64,\"first_name\":\"Beverly\",\"last_name\":\"Beatty\",\"email\":\"marguerite.schamberger@example.net\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"8gJidekKDF\",\"created_at\":\"2023-01-30T11:05:13.000000Z\",\"updated_at\":\"2023-01-30T11:05:13.000000Z\"}}', NULL, '2023-01-30 05:05:13', '2023-01-30 05:05:13'),
(67, 'default', 'created', 'App\\Models\\User', 'created', 65, NULL, NULL, '{\"attributes\":{\"id\":65,\"first_name\":\"Elvera\",\"last_name\":\"Ledner\",\"email\":\"reginald.maggio@example.net\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"vxAPW2mHuf\",\"created_at\":\"2023-01-30T11:05:13.000000Z\",\"updated_at\":\"2023-01-30T11:05:13.000000Z\"}}', NULL, '2023-01-30 05:05:13', '2023-01-30 05:05:13'),
(68, 'default', 'created', 'App\\Models\\User', 'created', 66, NULL, NULL, '{\"attributes\":{\"id\":66,\"first_name\":\"Shanelle\",\"last_name\":\"Terry\",\"email\":\"elody.oberbrunner@example.com\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"dd6SGqwrRn\",\"created_at\":\"2023-01-30T11:05:13.000000Z\",\"updated_at\":\"2023-01-30T11:05:13.000000Z\"}}', NULL, '2023-01-30 05:05:13', '2023-01-30 05:05:13'),
(69, 'default', 'created', 'App\\Models\\User', 'created', 67, NULL, NULL, '{\"attributes\":{\"id\":67,\"first_name\":\"Pascale\",\"last_name\":\"Wilkinson\",\"email\":\"ford44@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"rRypnV43F5\",\"created_at\":\"2023-01-30T11:05:13.000000Z\",\"updated_at\":\"2023-01-30T11:05:13.000000Z\"}}', NULL, '2023-01-30 05:05:13', '2023-01-30 05:05:13'),
(70, 'default', 'created', 'App\\Models\\User', 'created', 68, NULL, NULL, '{\"attributes\":{\"id\":68,\"first_name\":\"Destiny\",\"last_name\":\"Stamm\",\"email\":\"evie60@example.com\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"ShsuLLom2q\",\"created_at\":\"2023-01-30T11:05:13.000000Z\",\"updated_at\":\"2023-01-30T11:05:13.000000Z\"}}', NULL, '2023-01-30 05:05:13', '2023-01-30 05:05:13'),
(71, 'default', 'created', 'App\\Models\\User', 'created', 69, NULL, NULL, '{\"attributes\":{\"id\":69,\"first_name\":\"Marilie\",\"last_name\":\"Skiles\",\"email\":\"dibbert.karina@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"GWaQ3tWxfL\",\"created_at\":\"2023-01-30T11:05:13.000000Z\",\"updated_at\":\"2023-01-30T11:05:13.000000Z\"}}', NULL, '2023-01-30 05:05:13', '2023-01-30 05:05:13'),
(72, 'default', 'created', 'App\\Models\\User', 'created', 70, NULL, NULL, '{\"attributes\":{\"id\":70,\"first_name\":\"Theodora\",\"last_name\":\"Beatty\",\"email\":\"kreiger.elissa@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"O3j9EZJlsC\",\"created_at\":\"2023-01-30T11:05:14.000000Z\",\"updated_at\":\"2023-01-30T11:05:14.000000Z\"}}', NULL, '2023-01-30 05:05:14', '2023-01-30 05:05:14'),
(73, 'default', 'created', 'App\\Models\\User', 'created', 71, NULL, NULL, '{\"attributes\":{\"id\":71,\"first_name\":\"Isabel\",\"last_name\":\"Gibson\",\"email\":\"ogleichner@example.com\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"Rm2bgN7hV7\",\"created_at\":\"2023-01-30T11:05:14.000000Z\",\"updated_at\":\"2023-01-30T11:05:14.000000Z\"}}', NULL, '2023-01-30 05:05:14', '2023-01-30 05:05:14'),
(74, 'default', 'created', 'App\\Models\\User', 'created', 72, NULL, NULL, '{\"attributes\":{\"id\":72,\"first_name\":\"Mallory\",\"last_name\":\"Heller\",\"email\":\"larkin.stone@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"7k4RknawAm\",\"created_at\":\"2023-01-30T11:05:14.000000Z\",\"updated_at\":\"2023-01-30T11:05:14.000000Z\"}}', NULL, '2023-01-30 05:05:14', '2023-01-30 05:05:14'),
(75, 'default', 'created', 'App\\Models\\User', 'created', 73, NULL, NULL, '{\"attributes\":{\"id\":73,\"first_name\":\"Sigmund\",\"last_name\":\"Ortiz\",\"email\":\"roslyn74@example.com\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"GCaqhXJbmV\",\"created_at\":\"2023-01-30T11:05:14.000000Z\",\"updated_at\":\"2023-01-30T11:05:14.000000Z\"}}', NULL, '2023-01-30 05:05:14', '2023-01-30 05:05:14'),
(76, 'default', 'created', 'App\\Models\\User', 'created', 74, NULL, NULL, '{\"attributes\":{\"id\":74,\"first_name\":\"Genoveva\",\"last_name\":\"Towne\",\"email\":\"alyson35@example.com\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"zCb74E1GPV\",\"created_at\":\"2023-01-30T11:05:14.000000Z\",\"updated_at\":\"2023-01-30T11:05:14.000000Z\"}}', NULL, '2023-01-30 05:05:14', '2023-01-30 05:05:14'),
(77, 'default', 'created', 'App\\Models\\User', 'created', 75, NULL, NULL, '{\"attributes\":{\"id\":75,\"first_name\":\"Astrid\",\"last_name\":\"Metz\",\"email\":\"theodora.schaefer@example.com\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"RPhowGhT6M\",\"created_at\":\"2023-01-30T11:05:14.000000Z\",\"updated_at\":\"2023-01-30T11:05:14.000000Z\"}}', NULL, '2023-01-30 05:05:14', '2023-01-30 05:05:14'),
(78, 'default', 'created', 'App\\Models\\User', 'created', 76, NULL, NULL, '{\"attributes\":{\"id\":76,\"first_name\":\"Myah\",\"last_name\":\"Steuber\",\"email\":\"carole89@example.com\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"d4CW2Qw5Iw\",\"created_at\":\"2023-01-30T11:05:14.000000Z\",\"updated_at\":\"2023-01-30T11:05:14.000000Z\"}}', NULL, '2023-01-30 05:05:14', '2023-01-30 05:05:14'),
(79, 'default', 'created', 'App\\Models\\User', 'created', 77, NULL, NULL, '{\"attributes\":{\"id\":77,\"first_name\":\"Verla\",\"last_name\":\"Gerhold\",\"email\":\"bogisich.nona@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"B5FdbRvX2n\",\"created_at\":\"2023-01-30T11:05:14.000000Z\",\"updated_at\":\"2023-01-30T11:05:14.000000Z\"}}', NULL, '2023-01-30 05:05:14', '2023-01-30 05:05:14'),
(80, 'default', 'created', 'App\\Models\\User', 'created', 78, NULL, NULL, '{\"attributes\":{\"id\":78,\"first_name\":\"Leola\",\"last_name\":\"Toy\",\"email\":\"drew63@example.com\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"ENgDrPqWPe\",\"created_at\":\"2023-01-30T11:05:14.000000Z\",\"updated_at\":\"2023-01-30T11:05:14.000000Z\"}}', NULL, '2023-01-30 05:05:15', '2023-01-30 05:05:15'),
(81, 'default', 'created', 'App\\Models\\User', 'created', 79, NULL, NULL, '{\"attributes\":{\"id\":79,\"first_name\":\"Myrtle\",\"last_name\":\"Haley\",\"email\":\"ressie44@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"gJed20DG3Z\",\"created_at\":\"2023-01-30T11:05:15.000000Z\",\"updated_at\":\"2023-01-30T11:05:15.000000Z\"}}', NULL, '2023-01-30 05:05:15', '2023-01-30 05:05:15'),
(82, 'default', 'created', 'App\\Models\\User', 'created', 80, NULL, NULL, '{\"attributes\":{\"id\":80,\"first_name\":\"Benjamin\",\"last_name\":\"Jenkins\",\"email\":\"caitlyn.harvey@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"rmAN2rO4ym\",\"created_at\":\"2023-01-30T11:05:15.000000Z\",\"updated_at\":\"2023-01-30T11:05:15.000000Z\"}}', NULL, '2023-01-30 05:05:15', '2023-01-30 05:05:15'),
(83, 'default', 'created', 'App\\Models\\User', 'created', 81, NULL, NULL, '{\"attributes\":{\"id\":81,\"first_name\":\"Wayne\",\"last_name\":\"Wilderman\",\"email\":\"schuppe.esperanza@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"uLkLMDY4Oq\",\"created_at\":\"2023-01-30T11:05:15.000000Z\",\"updated_at\":\"2023-01-30T11:05:15.000000Z\"}}', NULL, '2023-01-30 05:05:15', '2023-01-30 05:05:15'),
(84, 'default', 'created', 'App\\Models\\User', 'created', 82, NULL, NULL, '{\"attributes\":{\"id\":82,\"first_name\":\"Jules\",\"last_name\":\"Keebler\",\"email\":\"mellie18@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"AxZeuFKmfY\",\"created_at\":\"2023-01-30T11:05:15.000000Z\",\"updated_at\":\"2023-01-30T11:05:15.000000Z\"}}', NULL, '2023-01-30 05:05:15', '2023-01-30 05:05:15'),
(85, 'default', 'created', 'App\\Models\\User', 'created', 83, NULL, NULL, '{\"attributes\":{\"id\":83,\"first_name\":\"Zaria\",\"last_name\":\"Wisoky\",\"email\":\"monica90@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"n8FYas3Wzp\",\"created_at\":\"2023-01-30T11:05:15.000000Z\",\"updated_at\":\"2023-01-30T11:05:15.000000Z\"}}', NULL, '2023-01-30 05:05:15', '2023-01-30 05:05:15'),
(86, 'default', 'created', 'App\\Models\\User', 'created', 84, NULL, NULL, '{\"attributes\":{\"id\":84,\"first_name\":\"Coy\",\"last_name\":\"Mante\",\"email\":\"reynolds.ciara@example.net\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"Hq7gz56jWg\",\"created_at\":\"2023-01-30T11:05:15.000000Z\",\"updated_at\":\"2023-01-30T11:05:15.000000Z\"}}', NULL, '2023-01-30 05:05:15', '2023-01-30 05:05:15'),
(87, 'default', 'created', 'App\\Models\\User', 'created', 85, NULL, NULL, '{\"attributes\":{\"id\":85,\"first_name\":\"Darlene\",\"last_name\":\"Breitenberg\",\"email\":\"gudrun.morissette@example.com\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"ofJqanD3yo\",\"created_at\":\"2023-01-30T11:05:15.000000Z\",\"updated_at\":\"2023-01-30T11:05:15.000000Z\"}}', NULL, '2023-01-30 05:05:15', '2023-01-30 05:05:15'),
(88, 'default', 'created', 'App\\Models\\User', 'created', 86, NULL, NULL, '{\"attributes\":{\"id\":86,\"first_name\":\"Lane\",\"last_name\":\"Sawayn\",\"email\":\"zcasper@example.com\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"Qll9tF02Ye\",\"created_at\":\"2023-01-30T11:05:16.000000Z\",\"updated_at\":\"2023-01-30T11:05:16.000000Z\"}}', NULL, '2023-01-30 05:05:16', '2023-01-30 05:05:16'),
(89, 'default', 'created', 'App\\Models\\User', 'created', 87, NULL, NULL, '{\"attributes\":{\"id\":87,\"first_name\":\"Lucile\",\"last_name\":\"Osinski\",\"email\":\"cooper15@example.com\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"UiuaKq4Mtl\",\"created_at\":\"2023-01-30T11:05:16.000000Z\",\"updated_at\":\"2023-01-30T11:05:16.000000Z\"}}', NULL, '2023-01-30 05:05:16', '2023-01-30 05:05:16'),
(90, 'default', 'created', 'App\\Models\\User', 'created', 88, NULL, NULL, '{\"attributes\":{\"id\":88,\"first_name\":\"Claire\",\"last_name\":\"Dooley\",\"email\":\"tianna70@example.com\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"nzzmvrqAiH\",\"created_at\":\"2023-01-30T11:05:16.000000Z\",\"updated_at\":\"2023-01-30T11:05:16.000000Z\"}}', NULL, '2023-01-30 05:05:16', '2023-01-30 05:05:16'),
(91, 'default', 'created', 'App\\Models\\User', 'created', 89, NULL, NULL, '{\"attributes\":{\"id\":89,\"first_name\":\"Yvette\",\"last_name\":\"Toy\",\"email\":\"marianna.jerde@example.net\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"wof9Yp8Wro\",\"created_at\":\"2023-01-30T11:05:16.000000Z\",\"updated_at\":\"2023-01-30T11:05:16.000000Z\"}}', NULL, '2023-01-30 05:05:16', '2023-01-30 05:05:16'),
(92, 'default', 'created', 'App\\Models\\User', 'created', 90, NULL, NULL, '{\"attributes\":{\"id\":90,\"first_name\":\"Evalyn\",\"last_name\":\"Abshire\",\"email\":\"chermiston@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"HTV2gdhxMm\",\"created_at\":\"2023-01-30T11:05:16.000000Z\",\"updated_at\":\"2023-01-30T11:05:16.000000Z\"}}', NULL, '2023-01-30 05:05:16', '2023-01-30 05:05:16'),
(93, 'default', 'created', 'App\\Models\\User', 'created', 91, NULL, NULL, '{\"attributes\":{\"id\":91,\"first_name\":\"Dasia\",\"last_name\":\"Bergnaum\",\"email\":\"xpaucek@example.com\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"9Opm7FMNdg\",\"created_at\":\"2023-01-30T11:05:16.000000Z\",\"updated_at\":\"2023-01-30T11:05:16.000000Z\"}}', NULL, '2023-01-30 05:05:16', '2023-01-30 05:05:16');
INSERT INTO `activity_log` (`id`, `log_name`, `description`, `subject_type`, `event`, `subject_id`, `causer_type`, `causer_id`, `properties`, `batch_uuid`, `created_at`, `updated_at`) VALUES
(94, 'default', 'created', 'App\\Models\\User', 'created', 92, NULL, NULL, '{\"attributes\":{\"id\":92,\"first_name\":\"Evangeline\",\"last_name\":\"Conroy\",\"email\":\"makenna53@example.com\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"qG7WhhST3M\",\"created_at\":\"2023-01-30T11:05:17.000000Z\",\"updated_at\":\"2023-01-30T11:05:17.000000Z\"}}', NULL, '2023-01-30 05:05:17', '2023-01-30 05:05:17'),
(95, 'default', 'created', 'App\\Models\\User', 'created', 93, NULL, NULL, '{\"attributes\":{\"id\":93,\"first_name\":\"Gina\",\"last_name\":\"Hilpert\",\"email\":\"piper55@example.net\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"bsVFGZV5zT\",\"created_at\":\"2023-01-30T11:05:17.000000Z\",\"updated_at\":\"2023-01-30T11:05:17.000000Z\"}}', NULL, '2023-01-30 05:05:17', '2023-01-30 05:05:17'),
(96, 'default', 'created', 'App\\Models\\User', 'created', 94, NULL, NULL, '{\"attributes\":{\"id\":94,\"first_name\":\"Cristina\",\"last_name\":\"Koss\",\"email\":\"jgrady@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"QOjqDacaIg\",\"created_at\":\"2023-01-30T11:05:17.000000Z\",\"updated_at\":\"2023-01-30T11:05:17.000000Z\"}}', NULL, '2023-01-30 05:05:17', '2023-01-30 05:05:17'),
(97, 'default', 'created', 'App\\Models\\User', 'created', 95, NULL, NULL, '{\"attributes\":{\"id\":95,\"first_name\":\"Alfonso\",\"last_name\":\"Smith\",\"email\":\"areichert@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"UUkcj5VYS5\",\"created_at\":\"2023-01-30T11:05:17.000000Z\",\"updated_at\":\"2023-01-30T11:05:17.000000Z\"}}', NULL, '2023-01-30 05:05:17', '2023-01-30 05:05:17'),
(98, 'default', 'created', 'App\\Models\\User', 'created', 96, NULL, NULL, '{\"attributes\":{\"id\":96,\"first_name\":\"Hilda\",\"last_name\":\"Crist\",\"email\":\"salma61@example.net\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"QKbmp8d3F5\",\"created_at\":\"2023-01-30T11:05:17.000000Z\",\"updated_at\":\"2023-01-30T11:05:17.000000Z\"}}', NULL, '2023-01-30 05:05:17', '2023-01-30 05:05:17'),
(99, 'default', 'created', 'App\\Models\\User', 'created', 97, NULL, NULL, '{\"attributes\":{\"id\":97,\"first_name\":\"Cindy\",\"last_name\":\"Bauch\",\"email\":\"schaefer.fernando@example.com\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"Ip4gTYFvXf\",\"created_at\":\"2023-01-30T11:05:17.000000Z\",\"updated_at\":\"2023-01-30T11:05:17.000000Z\"}}', NULL, '2023-01-30 05:05:17', '2023-01-30 05:05:17'),
(100, 'default', 'created', 'App\\Models\\User', 'created', 98, NULL, NULL, '{\"attributes\":{\"id\":98,\"first_name\":\"Van\",\"last_name\":\"Bogan\",\"email\":\"jacobson.adolfo@example.com\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"yjJUSXrakq\",\"created_at\":\"2023-01-30T11:05:17.000000Z\",\"updated_at\":\"2023-01-30T11:05:17.000000Z\"}}', NULL, '2023-01-30 05:05:17', '2023-01-30 05:05:17'),
(101, 'default', 'created', 'App\\Models\\User', 'created', 99, NULL, NULL, '{\"attributes\":{\"id\":99,\"first_name\":\"Magnolia\",\"last_name\":\"Donnelly\",\"email\":\"vidal.hodkiewicz@example.net\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"eeatBeIL6b\",\"created_at\":\"2023-01-30T11:05:17.000000Z\",\"updated_at\":\"2023-01-30T11:05:17.000000Z\"}}', NULL, '2023-01-30 05:05:17', '2023-01-30 05:05:17'),
(102, 'default', 'created', 'App\\Models\\User', 'created', 100, NULL, NULL, '{\"attributes\":{\"id\":100,\"first_name\":\"Mozelle\",\"last_name\":\"Kutch\",\"email\":\"rconroy@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"4aGgDbTzBK\",\"created_at\":\"2023-01-30T11:05:17.000000Z\",\"updated_at\":\"2023-01-30T11:05:17.000000Z\"}}', NULL, '2023-01-30 05:05:17', '2023-01-30 05:05:17'),
(103, 'default', 'created', 'App\\Models\\User', 'created', 101, NULL, NULL, '{\"attributes\":{\"id\":101,\"first_name\":\"Ashlynn\",\"last_name\":\"Treutel\",\"email\":\"schinner.thaddeus@example.org\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"IdQEP9xmzy\",\"created_at\":\"2023-01-30T11:05:17.000000Z\",\"updated_at\":\"2023-01-30T11:05:17.000000Z\"}}', NULL, '2023-01-30 05:05:17', '2023-01-30 05:05:17'),
(104, 'default', 'created', 'App\\Models\\User', 'created', 102, NULL, NULL, '{\"attributes\":{\"id\":102,\"first_name\":\"Mozell\",\"last_name\":\"Ruecker\",\"email\":\"zschmidt@example.com\",\"email_verified_at\":\"2023-01-30T11:05:04.000000Z\",\"password\":\"$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC\\/.og\\/at2.uheWG\\/igi\",\"api_token\":null,\"remember_token\":\"h6zfzsNxNy\",\"created_at\":\"2023-01-30T11:05:17.000000Z\",\"updated_at\":\"2023-01-30T11:05:17.000000Z\"}}', NULL, '2023-01-30 05:05:18', '2023-01-30 05:05:18'),
(105, 'default', 'created', 'App\\Models\\UserInfo', 'created', 3, NULL, NULL, '{\"attributes\":{\"id\":3,\"user_id\":3,\"avatar\":null,\"company\":\"Halvorson Group\",\"phone\":\"+1 (430) 280-0462\",\"website\":\"http:\\/\\/www.zieme.info\\/veritatis-id-molestiae-ut-atque.html\",\"country\":\"BA\",\"language\":\"be\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:18.000000Z\",\"updated_at\":\"2023-01-30T11:05:18.000000Z\"}}', NULL, '2023-01-30 05:05:18', '2023-01-30 05:05:18'),
(106, 'default', 'created', 'App\\Models\\UserInfo', 'created', 4, NULL, NULL, '{\"attributes\":{\"id\":4,\"user_id\":4,\"avatar\":null,\"company\":\"Von LLC\",\"phone\":\"845.285.4860\",\"website\":\"https:\\/\\/www.zboncak.com\\/reprehenderit-et-et-dolore-adipisci\",\"country\":\"IT\",\"language\":\"el\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:18.000000Z\",\"updated_at\":\"2023-01-30T11:05:18.000000Z\"}}', NULL, '2023-01-30 05:05:18', '2023-01-30 05:05:18'),
(107, 'default', 'created', 'App\\Models\\UserInfo', 'created', 5, NULL, NULL, '{\"attributes\":{\"id\":5,\"user_id\":5,\"avatar\":null,\"company\":\"Upton-Stamm\",\"phone\":\"1-561-410-5112\",\"website\":\"http:\\/\\/www.marquardt.info\\/voluptatem-consequatur-repellat-aperiam-ipsam\",\"country\":\"RE\",\"language\":\"ho\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:18.000000Z\",\"updated_at\":\"2023-01-30T11:05:18.000000Z\"}}', NULL, '2023-01-30 05:05:18', '2023-01-30 05:05:18'),
(108, 'default', 'created', 'App\\Models\\UserInfo', 'created', 6, NULL, NULL, '{\"attributes\":{\"id\":6,\"user_id\":6,\"avatar\":null,\"company\":\"Flatley, Howell and Lubowitz\",\"phone\":\"1-865-480-6435\",\"website\":\"https:\\/\\/deckow.com\\/aliquam-in-ut-autem-esse-voluptas-facilis.html\",\"country\":\"HT\",\"language\":\"ps\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:18.000000Z\",\"updated_at\":\"2023-01-30T11:05:18.000000Z\"}}', NULL, '2023-01-30 05:05:18', '2023-01-30 05:05:18'),
(109, 'default', 'created', 'App\\Models\\UserInfo', 'created', 7, NULL, NULL, '{\"attributes\":{\"id\":7,\"user_id\":7,\"avatar\":null,\"company\":\"Watsica, Gutkowski and Blanda\",\"phone\":\"+1-445-910-2778\",\"website\":\"http:\\/\\/marquardt.com\\/\",\"country\":\"CF\",\"language\":\"ab\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:18.000000Z\",\"updated_at\":\"2023-01-30T11:05:18.000000Z\"}}', NULL, '2023-01-30 05:05:18', '2023-01-30 05:05:18'),
(110, 'default', 'created', 'App\\Models\\UserInfo', 'created', 8, NULL, NULL, '{\"attributes\":{\"id\":8,\"user_id\":8,\"avatar\":null,\"company\":\"Deckow Ltd\",\"phone\":\"434.253.5867\",\"website\":\"http:\\/\\/www.balistreri.com\\/rem-exercitationem-illo-facilis-sunt.html\",\"country\":\"BN\",\"language\":\"iu\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:18.000000Z\",\"updated_at\":\"2023-01-30T11:05:18.000000Z\"}}', NULL, '2023-01-30 05:05:18', '2023-01-30 05:05:18'),
(111, 'default', 'created', 'App\\Models\\UserInfo', 'created', 9, NULL, NULL, '{\"attributes\":{\"id\":9,\"user_id\":9,\"avatar\":null,\"company\":\"Fisher, Mertz and Collins\",\"phone\":\"1-863-860-2159\",\"website\":\"https:\\/\\/www.hayes.com\\/placeat-quia-molestias-et-et-optio-minima-mollitia-excepturi\",\"country\":\"TT\",\"language\":\"ig\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:18.000000Z\",\"updated_at\":\"2023-01-30T11:05:18.000000Z\"}}', NULL, '2023-01-30 05:05:18', '2023-01-30 05:05:18'),
(112, 'default', 'created', 'App\\Models\\UserInfo', 'created', 10, NULL, NULL, '{\"attributes\":{\"id\":10,\"user_id\":10,\"avatar\":null,\"company\":\"Bartoletti Group\",\"phone\":\"+1-248-350-9269\",\"website\":\"http:\\/\\/gottlieb.com\\/non-accusamus-non-aut-dolores-aliquid-incidunt\",\"country\":\"CI\",\"language\":\"li\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:18.000000Z\",\"updated_at\":\"2023-01-30T11:05:18.000000Z\"}}', NULL, '2023-01-30 05:05:18', '2023-01-30 05:05:18'),
(113, 'default', 'created', 'App\\Models\\UserInfo', 'created', 11, NULL, NULL, '{\"attributes\":{\"id\":11,\"user_id\":11,\"avatar\":null,\"company\":\"Dickens-Parker\",\"phone\":\"+1.281.354.0408\",\"website\":\"http:\\/\\/kris.com\\/\",\"country\":\"BB\",\"language\":\"mg\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:19.000000Z\",\"updated_at\":\"2023-01-30T11:05:19.000000Z\"}}', NULL, '2023-01-30 05:05:19', '2023-01-30 05:05:19'),
(114, 'default', 'created', 'App\\Models\\UserInfo', 'created', 12, NULL, NULL, '{\"attributes\":{\"id\":12,\"user_id\":12,\"avatar\":null,\"company\":\"Homenick Inc\",\"phone\":\"+1 (320) 544-0921\",\"website\":\"http:\\/\\/www.lang.com\\/omnis-temporibus-dignissimos-delectus-delectus-ipsam-omnis-iusto-quos\",\"country\":\"HR\",\"language\":\"tr\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:19.000000Z\",\"updated_at\":\"2023-01-30T11:05:19.000000Z\"}}', NULL, '2023-01-30 05:05:19', '2023-01-30 05:05:19'),
(115, 'default', 'created', 'App\\Models\\UserInfo', 'created', 13, NULL, NULL, '{\"attributes\":{\"id\":13,\"user_id\":13,\"avatar\":null,\"company\":\"Lemke LLC\",\"phone\":\"980-678-7084\",\"website\":\"http:\\/\\/www.rogahn.org\\/\",\"country\":\"KI\",\"language\":\"az\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:19.000000Z\",\"updated_at\":\"2023-01-30T11:05:19.000000Z\"}}', NULL, '2023-01-30 05:05:19', '2023-01-30 05:05:19'),
(116, 'default', 'created', 'App\\Models\\UserInfo', 'created', 14, NULL, NULL, '{\"attributes\":{\"id\":14,\"user_id\":14,\"avatar\":null,\"company\":\"Braun Ltd\",\"phone\":\"1-629-228-6993\",\"website\":\"http:\\/\\/donnelly.com\\/\",\"country\":\"TZ\",\"language\":\"tt\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:19.000000Z\",\"updated_at\":\"2023-01-30T11:05:19.000000Z\"}}', NULL, '2023-01-30 05:05:19', '2023-01-30 05:05:19'),
(117, 'default', 'created', 'App\\Models\\UserInfo', 'created', 15, NULL, NULL, '{\"attributes\":{\"id\":15,\"user_id\":15,\"avatar\":null,\"company\":\"Reichel PLC\",\"phone\":\"1-769-782-1600\",\"website\":\"http:\\/\\/purdy.com\\/ullam-dolor-magni-tempora-eos\",\"country\":\"JP\",\"language\":\"sa\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:19.000000Z\",\"updated_at\":\"2023-01-30T11:05:19.000000Z\"}}', NULL, '2023-01-30 05:05:19', '2023-01-30 05:05:19'),
(118, 'default', 'created', 'App\\Models\\UserInfo', 'created', 16, NULL, NULL, '{\"attributes\":{\"id\":16,\"user_id\":16,\"avatar\":null,\"company\":\"Windler and Sons\",\"phone\":\"239-860-4177\",\"website\":\"https:\\/\\/schumm.net\\/odit-quo-omnis-qui-beatae-saepe-voluptate.html\",\"country\":\"TH\",\"language\":\"na\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:19.000000Z\",\"updated_at\":\"2023-01-30T11:05:19.000000Z\"}}', NULL, '2023-01-30 05:05:19', '2023-01-30 05:05:19'),
(119, 'default', 'created', 'App\\Models\\UserInfo', 'created', 17, NULL, NULL, '{\"attributes\":{\"id\":17,\"user_id\":17,\"avatar\":null,\"company\":\"Lowe, Vandervort and Feest\",\"phone\":\"707.763.6241\",\"website\":\"https:\\/\\/www.dach.biz\\/quisquam-placeat-expedita-quia\",\"country\":\"OM\",\"language\":\"nn\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:19.000000Z\",\"updated_at\":\"2023-01-30T11:05:19.000000Z\"}}', NULL, '2023-01-30 05:05:19', '2023-01-30 05:05:19'),
(120, 'default', 'created', 'App\\Models\\UserInfo', 'created', 18, NULL, NULL, '{\"attributes\":{\"id\":18,\"user_id\":18,\"avatar\":null,\"company\":\"Glover-Schneider\",\"phone\":\"1-979-819-8495\",\"website\":\"http:\\/\\/dare.org\\/\",\"country\":\"LC\",\"language\":\"an\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:20.000000Z\",\"updated_at\":\"2023-01-30T11:05:20.000000Z\"}}', NULL, '2023-01-30 05:05:20', '2023-01-30 05:05:20'),
(121, 'default', 'created', 'App\\Models\\UserInfo', 'created', 19, NULL, NULL, '{\"attributes\":{\"id\":19,\"user_id\":19,\"avatar\":null,\"company\":\"Mohr-Gulgowski\",\"phone\":\"850.235.1441\",\"website\":\"https:\\/\\/cassin.biz\\/atque-rerum-soluta-facere.html\",\"country\":\"IL\",\"language\":\"sa\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:20.000000Z\",\"updated_at\":\"2023-01-30T11:05:20.000000Z\"}}', NULL, '2023-01-30 05:05:20', '2023-01-30 05:05:20'),
(122, 'default', 'created', 'App\\Models\\UserInfo', 'created', 20, NULL, NULL, '{\"attributes\":{\"id\":20,\"user_id\":20,\"avatar\":null,\"company\":\"Schaefer, Turcotte and Quitzon\",\"phone\":\"208-900-5173\",\"website\":\"http:\\/\\/www.herman.info\\/\",\"country\":\"BI\",\"language\":\"fo\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:20.000000Z\",\"updated_at\":\"2023-01-30T11:05:20.000000Z\"}}', NULL, '2023-01-30 05:05:20', '2023-01-30 05:05:20'),
(123, 'default', 'created', 'App\\Models\\UserInfo', 'created', 21, NULL, NULL, '{\"attributes\":{\"id\":21,\"user_id\":21,\"avatar\":null,\"company\":\"Spinka-Hahn\",\"phone\":\"+1-512-875-0637\",\"website\":\"https:\\/\\/johns.org\\/perspiciatis-doloribus-ut-voluptas-omnis.html\",\"country\":\"DM\",\"language\":\"co\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:20.000000Z\",\"updated_at\":\"2023-01-30T11:05:20.000000Z\"}}', NULL, '2023-01-30 05:05:20', '2023-01-30 05:05:20'),
(124, 'default', 'created', 'App\\Models\\UserInfo', 'created', 22, NULL, NULL, '{\"attributes\":{\"id\":22,\"user_id\":22,\"avatar\":null,\"company\":\"Boehm, Raynor and Cruickshank\",\"phone\":\"+16468822256\",\"website\":\"http:\\/\\/krajcik.info\\/dolores-nam-nulla-aperiam-eius\",\"country\":\"RU\",\"language\":\"lu\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:20.000000Z\",\"updated_at\":\"2023-01-30T11:05:20.000000Z\"}}', NULL, '2023-01-30 05:05:20', '2023-01-30 05:05:20'),
(125, 'default', 'created', 'App\\Models\\UserInfo', 'created', 23, NULL, NULL, '{\"attributes\":{\"id\":23,\"user_id\":23,\"avatar\":null,\"company\":\"Morar-Champlin\",\"phone\":\"+1-864-476-3168\",\"website\":\"https:\\/\\/www.schuster.com\\/voluptatem-ducimus-facere-cum-odit\",\"country\":\"CL\",\"language\":\"ig\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:20.000000Z\",\"updated_at\":\"2023-01-30T11:05:20.000000Z\"}}', NULL, '2023-01-30 05:05:20', '2023-01-30 05:05:20'),
(126, 'default', 'created', 'App\\Models\\UserInfo', 'created', 24, NULL, NULL, '{\"attributes\":{\"id\":24,\"user_id\":24,\"avatar\":null,\"company\":\"Torp-Altenwerth\",\"phone\":\"+1-574-241-0944\",\"website\":\"https:\\/\\/goldner.com\\/et-aut-est-eius-a-reprehenderit-quod-quia.html\",\"country\":\"UM\",\"language\":\"ch\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:20.000000Z\",\"updated_at\":\"2023-01-30T11:05:20.000000Z\"}}', NULL, '2023-01-30 05:05:20', '2023-01-30 05:05:20'),
(127, 'default', 'created', 'App\\Models\\UserInfo', 'created', 25, NULL, NULL, '{\"attributes\":{\"id\":25,\"user_id\":25,\"avatar\":null,\"company\":\"Harber-Renner\",\"phone\":\"812.284.0837\",\"website\":\"https:\\/\\/gerhold.com\\/sunt-ab-quidem-sunt-incidunt-quidem-sunt.html\",\"country\":\"LS\",\"language\":\"pi\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:21.000000Z\",\"updated_at\":\"2023-01-30T11:05:21.000000Z\"}}', NULL, '2023-01-30 05:05:21', '2023-01-30 05:05:21'),
(128, 'default', 'created', 'App\\Models\\UserInfo', 'created', 26, NULL, NULL, '{\"attributes\":{\"id\":26,\"user_id\":26,\"avatar\":null,\"company\":\"Schinner PLC\",\"phone\":\"508.672.3563\",\"website\":\"https:\\/\\/oberbrunner.com\\/est-quaerat-nam-quia-non.html\",\"country\":\"MV\",\"language\":\"mt\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:21.000000Z\",\"updated_at\":\"2023-01-30T11:05:21.000000Z\"}}', NULL, '2023-01-30 05:05:21', '2023-01-30 05:05:21'),
(129, 'default', 'created', 'App\\Models\\UserInfo', 'created', 27, NULL, NULL, '{\"attributes\":{\"id\":27,\"user_id\":27,\"avatar\":null,\"company\":\"Dibbert PLC\",\"phone\":\"386.765.2103\",\"website\":\"https:\\/\\/www.gislason.org\\/reiciendis-in-vero-suscipit-dolore-aspernatur-fugit-et\",\"country\":\"SI\",\"language\":\"mi\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:21.000000Z\",\"updated_at\":\"2023-01-30T11:05:21.000000Z\"}}', NULL, '2023-01-30 05:05:21', '2023-01-30 05:05:21'),
(130, 'default', 'created', 'App\\Models\\UserInfo', 'created', 28, NULL, NULL, '{\"attributes\":{\"id\":28,\"user_id\":28,\"avatar\":null,\"company\":\"Watsica, Maggio and Christiansen\",\"phone\":\"(845) 831-9784\",\"website\":\"http:\\/\\/www.gibson.org\\/rerum-distinctio-vel-hic\",\"country\":\"IM\",\"language\":\"nr\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:21.000000Z\",\"updated_at\":\"2023-01-30T11:05:21.000000Z\"}}', NULL, '2023-01-30 05:05:21', '2023-01-30 05:05:21'),
(131, 'default', 'created', 'App\\Models\\UserInfo', 'created', 29, NULL, NULL, '{\"attributes\":{\"id\":29,\"user_id\":29,\"avatar\":null,\"company\":\"Boyer PLC\",\"phone\":\"458-508-8836\",\"website\":\"http:\\/\\/www.runolfsson.com\\/voluptate-temporibus-minima-quia-reiciendis\",\"country\":\"VI\",\"language\":\"si\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:21.000000Z\",\"updated_at\":\"2023-01-30T11:05:21.000000Z\"}}', NULL, '2023-01-30 05:05:21', '2023-01-30 05:05:21'),
(132, 'default', 'created', 'App\\Models\\UserInfo', 'created', 30, NULL, NULL, '{\"attributes\":{\"id\":30,\"user_id\":30,\"avatar\":null,\"company\":\"Lehner PLC\",\"phone\":\"+1-341-990-7613\",\"website\":\"http:\\/\\/www.berge.com\\/architecto-vel-rerum-fuga-iste-sunt-aliquid.html\",\"country\":\"MV\",\"language\":\"lt\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:21.000000Z\",\"updated_at\":\"2023-01-30T11:05:21.000000Z\"}}', NULL, '2023-01-30 05:05:21', '2023-01-30 05:05:21'),
(133, 'default', 'created', 'App\\Models\\UserInfo', 'created', 31, NULL, NULL, '{\"attributes\":{\"id\":31,\"user_id\":31,\"avatar\":null,\"company\":\"Cormier and Sons\",\"phone\":\"352.465.0917\",\"website\":\"http:\\/\\/www.kuhlman.com\\/saepe-doloribus-est-possimus-aut-ex-repellat\",\"country\":\"PA\",\"language\":\"ak\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:21.000000Z\",\"updated_at\":\"2023-01-30T11:05:21.000000Z\"}}', NULL, '2023-01-30 05:05:21', '2023-01-30 05:05:21'),
(134, 'default', 'created', 'App\\Models\\UserInfo', 'created', 32, NULL, NULL, '{\"attributes\":{\"id\":32,\"user_id\":32,\"avatar\":null,\"company\":\"Stehr-Moen\",\"phone\":\"701.694.1027\",\"website\":\"http:\\/\\/www.gutmann.info\\/\",\"country\":\"QA\",\"language\":\"pi\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:21.000000Z\",\"updated_at\":\"2023-01-30T11:05:21.000000Z\"}}', NULL, '2023-01-30 05:05:21', '2023-01-30 05:05:21'),
(135, 'default', 'created', 'App\\Models\\UserInfo', 'created', 33, NULL, NULL, '{\"attributes\":{\"id\":33,\"user_id\":33,\"avatar\":null,\"company\":\"Wunsch, Lesch and Little\",\"phone\":\"628-551-5050\",\"website\":\"http:\\/\\/www.moen.biz\\/impedit-accusantium-dolorem-qui-ea-vero-sint-blanditiis\",\"country\":\"TM\",\"language\":\"ps\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:21.000000Z\",\"updated_at\":\"2023-01-30T11:05:21.000000Z\"}}', NULL, '2023-01-30 05:05:22', '2023-01-30 05:05:22'),
(136, 'default', 'created', 'App\\Models\\UserInfo', 'created', 34, NULL, NULL, '{\"attributes\":{\"id\":34,\"user_id\":34,\"avatar\":null,\"company\":\"McClure, Braun and Bashirian\",\"phone\":\"562-269-7745\",\"website\":\"https:\\/\\/crist.com\\/molestiae-laudantium-aliquam-est-sint.html\",\"country\":\"NI\",\"language\":\"or\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:22.000000Z\",\"updated_at\":\"2023-01-30T11:05:22.000000Z\"}}', NULL, '2023-01-30 05:05:22', '2023-01-30 05:05:22'),
(137, 'default', 'created', 'App\\Models\\UserInfo', 'created', 35, NULL, NULL, '{\"attributes\":{\"id\":35,\"user_id\":35,\"avatar\":null,\"company\":\"Bergstrom Group\",\"phone\":\"+13808162577\",\"website\":\"http:\\/\\/www.mayert.biz\\/earum-et-tempore-quae\",\"country\":\"CZ\",\"language\":\"lv\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:22.000000Z\",\"updated_at\":\"2023-01-30T11:05:22.000000Z\"}}', NULL, '2023-01-30 05:05:22', '2023-01-30 05:05:22'),
(138, 'default', 'created', 'App\\Models\\UserInfo', 'created', 36, NULL, NULL, '{\"attributes\":{\"id\":36,\"user_id\":36,\"avatar\":null,\"company\":\"Langworth Ltd\",\"phone\":\"(725) 868-5735\",\"website\":\"http:\\/\\/crooks.biz\\/numquam-laborum-sequi-pariatur-ut-omnis\",\"country\":\"DJ\",\"language\":\"ik\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:22.000000Z\",\"updated_at\":\"2023-01-30T11:05:22.000000Z\"}}', NULL, '2023-01-30 05:05:22', '2023-01-30 05:05:22'),
(139, 'default', 'created', 'App\\Models\\UserInfo', 'created', 37, NULL, NULL, '{\"attributes\":{\"id\":37,\"user_id\":37,\"avatar\":null,\"company\":\"Rath-Kassulke\",\"phone\":\"+13079491139\",\"website\":\"http:\\/\\/www.bartoletti.com\\/facilis-deserunt-molestiae-velit-non.html\",\"country\":\"DK\",\"language\":\"ks\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:22.000000Z\",\"updated_at\":\"2023-01-30T11:05:22.000000Z\"}}', NULL, '2023-01-30 05:05:22', '2023-01-30 05:05:22'),
(140, 'default', 'created', 'App\\Models\\UserInfo', 'created', 38, NULL, NULL, '{\"attributes\":{\"id\":38,\"user_id\":38,\"avatar\":null,\"company\":\"Wiza LLC\",\"phone\":\"725-447-2591\",\"website\":\"http:\\/\\/www.kreiger.com\\/eos-est-illo-nulla-itaque-necessitatibus-repudiandae-officiis.html\",\"country\":\"EC\",\"language\":\"qu\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:22.000000Z\",\"updated_at\":\"2023-01-30T11:05:22.000000Z\"}}', NULL, '2023-01-30 05:05:22', '2023-01-30 05:05:22'),
(141, 'default', 'created', 'App\\Models\\UserInfo', 'created', 39, NULL, NULL, '{\"attributes\":{\"id\":39,\"user_id\":39,\"avatar\":null,\"company\":\"Durgan Ltd\",\"phone\":\"223-405-5697\",\"website\":\"http:\\/\\/lang.com\\/sed-omnis-quo-ex-qui\",\"country\":\"MQ\",\"language\":\"ky\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:22.000000Z\",\"updated_at\":\"2023-01-30T11:05:22.000000Z\"}}', NULL, '2023-01-30 05:05:22', '2023-01-30 05:05:22'),
(142, 'default', 'created', 'App\\Models\\UserInfo', 'created', 40, NULL, NULL, '{\"attributes\":{\"id\":40,\"user_id\":40,\"avatar\":null,\"company\":\"Gutkowski Inc\",\"phone\":\"985-941-7339\",\"website\":\"https:\\/\\/www.vandervort.biz\\/sapiente-quo-sapiente-vero-vel-rerum\",\"country\":\"GE\",\"language\":\"it\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:22.000000Z\",\"updated_at\":\"2023-01-30T11:05:22.000000Z\"}}', NULL, '2023-01-30 05:05:22', '2023-01-30 05:05:22'),
(143, 'default', 'created', 'App\\Models\\UserInfo', 'created', 41, NULL, NULL, '{\"attributes\":{\"id\":41,\"user_id\":41,\"avatar\":null,\"company\":\"Price PLC\",\"phone\":\"219-808-7763\",\"website\":\"http:\\/\\/carroll.org\\/omnis-provident-autem-et-laudantium-sunt\",\"country\":\"CY\",\"language\":\"ss\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:23.000000Z\",\"updated_at\":\"2023-01-30T11:05:23.000000Z\"}}', NULL, '2023-01-30 05:05:23', '2023-01-30 05:05:23'),
(144, 'default', 'created', 'App\\Models\\UserInfo', 'created', 42, NULL, NULL, '{\"attributes\":{\"id\":42,\"user_id\":42,\"avatar\":null,\"company\":\"Labadie-Hodkiewicz\",\"phone\":\"351.465.2959\",\"website\":\"https:\\/\\/www.grimes.com\\/ducimus-officia-vero-error-ipsam\",\"country\":\"UZ\",\"language\":\"en\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:23.000000Z\",\"updated_at\":\"2023-01-30T11:05:23.000000Z\"}}', NULL, '2023-01-30 05:05:23', '2023-01-30 05:05:23'),
(145, 'default', 'created', 'App\\Models\\UserInfo', 'created', 43, NULL, NULL, '{\"attributes\":{\"id\":43,\"user_id\":43,\"avatar\":null,\"company\":\"Grimes-Greenholt\",\"phone\":\"+1 (351) 844-8219\",\"website\":\"http:\\/\\/www.rohan.com\\/\",\"country\":\"CA\",\"language\":\"ne\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:23.000000Z\",\"updated_at\":\"2023-01-30T11:05:23.000000Z\"}}', NULL, '2023-01-30 05:05:23', '2023-01-30 05:05:23'),
(146, 'default', 'created', 'App\\Models\\UserInfo', 'created', 44, NULL, NULL, '{\"attributes\":{\"id\":44,\"user_id\":44,\"avatar\":null,\"company\":\"Hartmann, Crooks and Hodkiewicz\",\"phone\":\"+16572310289\",\"website\":\"http:\\/\\/spencer.com\\/qui-eveniet-fuga-velit-quae-occaecati-distinctio-voluptatem\",\"country\":\"EE\",\"language\":\"cs\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:23.000000Z\",\"updated_at\":\"2023-01-30T11:05:23.000000Z\"}}', NULL, '2023-01-30 05:05:23', '2023-01-30 05:05:23'),
(147, 'default', 'created', 'App\\Models\\UserInfo', 'created', 45, NULL, NULL, '{\"attributes\":{\"id\":45,\"user_id\":45,\"avatar\":null,\"company\":\"Deckow, Mueller and Turner\",\"phone\":\"1-602-614-7496\",\"website\":\"http:\\/\\/www.hintz.com\\/omnis-qui-ab-qui-quibusdam-vero-itaque-alias.html\",\"country\":\"ZA\",\"language\":\"su\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:23.000000Z\",\"updated_at\":\"2023-01-30T11:05:23.000000Z\"}}', NULL, '2023-01-30 05:05:23', '2023-01-30 05:05:23'),
(148, 'default', 'created', 'App\\Models\\UserInfo', 'created', 46, NULL, NULL, '{\"attributes\":{\"id\":46,\"user_id\":46,\"avatar\":null,\"company\":\"Brown LLC\",\"phone\":\"706.873.7849\",\"website\":\"https:\\/\\/www.metz.com\\/quibusdam-numquam-voluptatem-rem-maxime-quos-sed-fugit-autem\",\"country\":\"BZ\",\"language\":\"se\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:23.000000Z\",\"updated_at\":\"2023-01-30T11:05:23.000000Z\"}}', NULL, '2023-01-30 05:05:23', '2023-01-30 05:05:23'),
(149, 'default', 'created', 'App\\Models\\UserInfo', 'created', 47, NULL, NULL, '{\"attributes\":{\"id\":47,\"user_id\":47,\"avatar\":null,\"company\":\"Predovic-Tillman\",\"phone\":\"+1.469.318.8238\",\"website\":\"https:\\/\\/kautzer.com\\/laboriosam-rem-inventore-in-iusto-voluptatem.html\",\"country\":\"LI\",\"language\":\"cv\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:23.000000Z\",\"updated_at\":\"2023-01-30T11:05:23.000000Z\"}}', NULL, '2023-01-30 05:05:23', '2023-01-30 05:05:23'),
(150, 'default', 'created', 'App\\Models\\UserInfo', 'created', 48, NULL, NULL, '{\"attributes\":{\"id\":48,\"user_id\":48,\"avatar\":null,\"company\":\"Balistreri-Stanton\",\"phone\":\"(858) 826-4734\",\"website\":\"http:\\/\\/www.kautzer.org\\/officia-sint-nesciunt-et-omnis-exercitationem-quis-perspiciatis-voluptatibus.html\",\"country\":\"GE\",\"language\":\"te\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:23.000000Z\",\"updated_at\":\"2023-01-30T11:05:23.000000Z\"}}', NULL, '2023-01-30 05:05:24', '2023-01-30 05:05:24'),
(151, 'default', 'created', 'App\\Models\\UserInfo', 'created', 49, NULL, NULL, '{\"attributes\":{\"id\":49,\"user_id\":49,\"avatar\":null,\"company\":\"Nicolas-McLaughlin\",\"phone\":\"1-937-565-7128\",\"website\":\"https:\\/\\/kreiger.com\\/dolor-nulla-nesciunt-quis-tempora-necessitatibus-enim-qui.html\",\"country\":\"SI\",\"language\":\"st\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:24.000000Z\",\"updated_at\":\"2023-01-30T11:05:24.000000Z\"}}', NULL, '2023-01-30 05:05:24', '2023-01-30 05:05:24'),
(152, 'default', 'created', 'App\\Models\\UserInfo', 'created', 50, NULL, NULL, '{\"attributes\":{\"id\":50,\"user_id\":50,\"avatar\":null,\"company\":\"Hodkiewicz-Rice\",\"phone\":\"1-870-742-1873\",\"website\":\"http:\\/\\/www.vonrueden.com\\/praesentium-sit-ut-voluptatum-quae\",\"country\":\"JP\",\"language\":\"to\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:24.000000Z\",\"updated_at\":\"2023-01-30T11:05:24.000000Z\"}}', NULL, '2023-01-30 05:05:24', '2023-01-30 05:05:24'),
(153, 'default', 'created', 'App\\Models\\UserInfo', 'created', 51, NULL, NULL, '{\"attributes\":{\"id\":51,\"user_id\":51,\"avatar\":null,\"company\":\"Rodriguez-Robel\",\"phone\":\"+1 (860) 497-6952\",\"website\":\"https:\\/\\/www.cartwright.com\\/necessitatibus-recusandae-voluptas-omnis-consectetur-voluptatem-ducimus-laudantium\",\"country\":\"CK\",\"language\":\"ff\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:24.000000Z\",\"updated_at\":\"2023-01-30T11:05:24.000000Z\"}}', NULL, '2023-01-30 05:05:24', '2023-01-30 05:05:24'),
(154, 'default', 'created', 'App\\Models\\UserInfo', 'created', 52, NULL, NULL, '{\"attributes\":{\"id\":52,\"user_id\":52,\"avatar\":null,\"company\":\"Wisozk, O\'Hara and Hermann\",\"phone\":\"757.557.0993\",\"website\":\"http:\\/\\/www.shanahan.net\\/quam-nihil-qui-illum-quis\",\"country\":\"FR\",\"language\":\"fi\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:24.000000Z\",\"updated_at\":\"2023-01-30T11:05:24.000000Z\"}}', NULL, '2023-01-30 05:05:24', '2023-01-30 05:05:24'),
(155, 'default', 'created', 'App\\Models\\UserInfo', 'created', 53, NULL, NULL, '{\"attributes\":{\"id\":53,\"user_id\":53,\"avatar\":null,\"company\":\"Lubowitz-Swift\",\"phone\":\"+1 (443) 268-9700\",\"website\":\"https:\\/\\/ortiz.biz\\/molestiae-fugit-est-alias-quisquam-fugiat-magnam-rerum.html\",\"country\":\"NE\",\"language\":\"kw\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:24.000000Z\",\"updated_at\":\"2023-01-30T11:05:24.000000Z\"}}', NULL, '2023-01-30 05:05:24', '2023-01-30 05:05:24'),
(156, 'default', 'created', 'App\\Models\\UserInfo', 'created', 54, NULL, NULL, '{\"attributes\":{\"id\":54,\"user_id\":54,\"avatar\":null,\"company\":\"Ritchie-Schneider\",\"phone\":\"+18708464490\",\"website\":\"https:\\/\\/www.veum.net\\/consequatur-et-et-placeat-a\",\"country\":\"CR\",\"language\":\"ht\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:24.000000Z\",\"updated_at\":\"2023-01-30T11:05:24.000000Z\"}}', NULL, '2023-01-30 05:05:24', '2023-01-30 05:05:24'),
(157, 'default', 'created', 'App\\Models\\UserInfo', 'created', 55, NULL, NULL, '{\"attributes\":{\"id\":55,\"user_id\":55,\"avatar\":null,\"company\":\"Franecki-Littel\",\"phone\":\"+1-540-326-5204\",\"website\":\"http:\\/\\/www.weissnat.com\\/eos-numquam-voluptatem-sint-voluptas-enim\",\"country\":\"AR\",\"language\":\"sr\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:24.000000Z\",\"updated_at\":\"2023-01-30T11:05:24.000000Z\"}}', NULL, '2023-01-30 05:05:24', '2023-01-30 05:05:24'),
(158, 'default', 'created', 'App\\Models\\UserInfo', 'created', 56, NULL, NULL, '{\"attributes\":{\"id\":56,\"user_id\":56,\"avatar\":null,\"company\":\"Altenwerth, Carter and Roob\",\"phone\":\"708-355-9725\",\"website\":\"http:\\/\\/hayes.org\\/\",\"country\":\"IL\",\"language\":\"gd\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:24.000000Z\",\"updated_at\":\"2023-01-30T11:05:24.000000Z\"}}', NULL, '2023-01-30 05:05:24', '2023-01-30 05:05:24'),
(159, 'default', 'created', 'App\\Models\\UserInfo', 'created', 57, NULL, NULL, '{\"attributes\":{\"id\":57,\"user_id\":57,\"avatar\":null,\"company\":\"Keeling Ltd\",\"phone\":\"(657) 242-8735\",\"website\":\"http:\\/\\/fritsch.net\\/\",\"country\":\"PY\",\"language\":\"hz\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:24.000000Z\",\"updated_at\":\"2023-01-30T11:05:24.000000Z\"}}', NULL, '2023-01-30 05:05:25', '2023-01-30 05:05:25'),
(160, 'default', 'created', 'App\\Models\\UserInfo', 'created', 58, NULL, NULL, '{\"attributes\":{\"id\":58,\"user_id\":58,\"avatar\":null,\"company\":\"Dare, Greenfelder and Cartwright\",\"phone\":\"+1.253.351.1265\",\"website\":\"http:\\/\\/www.dooley.com\\/facilis-et-aut-id\",\"country\":\"EC\",\"language\":\"cu\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:25.000000Z\",\"updated_at\":\"2023-01-30T11:05:25.000000Z\"}}', NULL, '2023-01-30 05:05:25', '2023-01-30 05:05:25'),
(161, 'default', 'created', 'App\\Models\\UserInfo', 'created', 59, NULL, NULL, '{\"attributes\":{\"id\":59,\"user_id\":59,\"avatar\":null,\"company\":\"Willms-Konopelski\",\"phone\":\"1-559-743-4122\",\"website\":\"https:\\/\\/swaniawski.com\\/voluptas-doloribus-voluptas-sit-ullam.html\",\"country\":\"JP\",\"language\":\"ur\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:25.000000Z\",\"updated_at\":\"2023-01-30T11:05:25.000000Z\"}}', NULL, '2023-01-30 05:05:25', '2023-01-30 05:05:25'),
(162, 'default', 'created', 'App\\Models\\UserInfo', 'created', 60, NULL, NULL, '{\"attributes\":{\"id\":60,\"user_id\":60,\"avatar\":null,\"company\":\"Huel-Daugherty\",\"phone\":\"(425) 393-5322\",\"website\":\"http:\\/\\/beahan.com\\/\",\"country\":\"CA\",\"language\":\"fy\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:25.000000Z\",\"updated_at\":\"2023-01-30T11:05:25.000000Z\"}}', NULL, '2023-01-30 05:05:25', '2023-01-30 05:05:25'),
(163, 'default', 'created', 'App\\Models\\UserInfo', 'created', 61, NULL, NULL, '{\"attributes\":{\"id\":61,\"user_id\":61,\"avatar\":null,\"company\":\"Treutel Ltd\",\"phone\":\"+1-779-492-7096\",\"website\":\"https:\\/\\/www.dubuque.com\\/earum-asperiores-aut-sed-laboriosam\",\"country\":\"NI\",\"language\":\"gn\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:25.000000Z\",\"updated_at\":\"2023-01-30T11:05:25.000000Z\"}}', NULL, '2023-01-30 05:05:25', '2023-01-30 05:05:25'),
(164, 'default', 'created', 'App\\Models\\UserInfo', 'created', 62, NULL, NULL, '{\"attributes\":{\"id\":62,\"user_id\":62,\"avatar\":null,\"company\":\"Cremin PLC\",\"phone\":\"986-589-2196\",\"website\":\"http:\\/\\/stanton.com\\/non-possimus-quam-harum-aut-a-similique\",\"country\":\"EG\",\"language\":\"ko\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:25.000000Z\",\"updated_at\":\"2023-01-30T11:05:25.000000Z\"}}', NULL, '2023-01-30 05:05:25', '2023-01-30 05:05:25'),
(165, 'default', 'created', 'App\\Models\\UserInfo', 'created', 63, NULL, NULL, '{\"attributes\":{\"id\":63,\"user_id\":63,\"avatar\":null,\"company\":\"O\'Keefe, Gaylord and Stiedemann\",\"phone\":\"1-501-725-7187\",\"website\":\"http:\\/\\/www.medhurst.net\\/\",\"country\":\"BJ\",\"language\":\"hz\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:25.000000Z\",\"updated_at\":\"2023-01-30T11:05:25.000000Z\"}}', NULL, '2023-01-30 05:05:25', '2023-01-30 05:05:25'),
(166, 'default', 'created', 'App\\Models\\UserInfo', 'created', 64, NULL, NULL, '{\"attributes\":{\"id\":64,\"user_id\":64,\"avatar\":null,\"company\":\"Rohan-Runolfsdottir\",\"phone\":\"+1.818.467.6683\",\"website\":\"http:\\/\\/jerde.com\\/officiis-nemo-dolorem-excepturi\",\"country\":\"FM\",\"language\":\"af\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:25.000000Z\",\"updated_at\":\"2023-01-30T11:05:25.000000Z\"}}', NULL, '2023-01-30 05:05:26', '2023-01-30 05:05:26'),
(167, 'default', 'created', 'App\\Models\\UserInfo', 'created', 65, NULL, NULL, '{\"attributes\":{\"id\":65,\"user_id\":65,\"avatar\":null,\"company\":\"Wolf LLC\",\"phone\":\"+1-321-875-1048\",\"website\":\"http:\\/\\/lynch.com\\/consectetur-odio-sint-cumque-eaque.html\",\"country\":\"ME\",\"language\":\"sw\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:26.000000Z\",\"updated_at\":\"2023-01-30T11:05:26.000000Z\"}}', NULL, '2023-01-30 05:05:26', '2023-01-30 05:05:26'),
(168, 'default', 'created', 'App\\Models\\UserInfo', 'created', 66, NULL, NULL, '{\"attributes\":{\"id\":66,\"user_id\":66,\"avatar\":null,\"company\":\"Kling PLC\",\"phone\":\"909-869-2330\",\"website\":\"http:\\/\\/schmeler.com\\/assumenda-nam-aspernatur-enim-est-delectus-sed-voluptatem\",\"country\":\"KI\",\"language\":\"ie\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:26.000000Z\",\"updated_at\":\"2023-01-30T11:05:26.000000Z\"}}', NULL, '2023-01-30 05:05:26', '2023-01-30 05:05:26'),
(169, 'default', 'created', 'App\\Models\\UserInfo', 'created', 67, NULL, NULL, '{\"attributes\":{\"id\":67,\"user_id\":67,\"avatar\":null,\"company\":\"Haley, Osinski and Von\",\"phone\":\"1-602-210-8939\",\"website\":\"http:\\/\\/langosh.org\\/corporis-qui-exercitationem-quod-fugiat-laudantium-reprehenderit.html\",\"country\":\"ER\",\"language\":\"vi\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:26.000000Z\",\"updated_at\":\"2023-01-30T11:05:26.000000Z\"}}', NULL, '2023-01-30 05:05:26', '2023-01-30 05:05:26'),
(170, 'default', 'created', 'App\\Models\\UserInfo', 'created', 68, NULL, NULL, '{\"attributes\":{\"id\":68,\"user_id\":68,\"avatar\":null,\"company\":\"Fisher PLC\",\"phone\":\"239.313.0694\",\"website\":\"http:\\/\\/zulauf.com\\/ea-dolorum-sint-similique\",\"country\":\"KI\",\"language\":\"be\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:26.000000Z\",\"updated_at\":\"2023-01-30T11:05:26.000000Z\"}}', NULL, '2023-01-30 05:05:26', '2023-01-30 05:05:26'),
(171, 'default', 'created', 'App\\Models\\UserInfo', 'created', 69, NULL, NULL, '{\"attributes\":{\"id\":69,\"user_id\":69,\"avatar\":null,\"company\":\"Bosco LLC\",\"phone\":\"+16783570770\",\"website\":\"http:\\/\\/www.reilly.com\\/sequi-non-sint-non-natus\",\"country\":\"ML\",\"language\":\"kk\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:26.000000Z\",\"updated_at\":\"2023-01-30T11:05:26.000000Z\"}}', NULL, '2023-01-30 05:05:26', '2023-01-30 05:05:26'),
(172, 'default', 'created', 'App\\Models\\UserInfo', 'created', 70, NULL, NULL, '{\"attributes\":{\"id\":70,\"user_id\":70,\"avatar\":null,\"company\":\"Torp LLC\",\"phone\":\"1-434-816-4673\",\"website\":\"http:\\/\\/www.skiles.com\\/modi-recusandae-repellat-beatae-quos-suscipit-fugit-exercitationem-necessitatibus.html\",\"country\":\"HT\",\"language\":\"id\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:26.000000Z\",\"updated_at\":\"2023-01-30T11:05:26.000000Z\"}}', NULL, '2023-01-30 05:05:26', '2023-01-30 05:05:26'),
(173, 'default', 'created', 'App\\Models\\UserInfo', 'created', 71, NULL, NULL, '{\"attributes\":{\"id\":71,\"user_id\":71,\"avatar\":null,\"company\":\"Runolfsson Ltd\",\"phone\":\"(283) 709-1775\",\"website\":\"https:\\/\\/hand.com\\/reprehenderit-aut-magni-et-ut-ut-vel.html\",\"country\":\"GD\",\"language\":\"nd\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:26.000000Z\",\"updated_at\":\"2023-01-30T11:05:26.000000Z\"}}', NULL, '2023-01-30 05:05:26', '2023-01-30 05:05:26'),
(174, 'default', 'created', 'App\\Models\\UserInfo', 'created', 72, NULL, NULL, '{\"attributes\":{\"id\":72,\"user_id\":72,\"avatar\":null,\"company\":\"Greenholt-Prohaska\",\"phone\":\"541.910.9333\",\"website\":\"https:\\/\\/kiehn.info\\/consectetur-aliquid-aut-qui-labore.html\",\"country\":\"LT\",\"language\":\"xh\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:26.000000Z\",\"updated_at\":\"2023-01-30T11:05:26.000000Z\"}}', NULL, '2023-01-30 05:05:27', '2023-01-30 05:05:27'),
(175, 'default', 'created', 'App\\Models\\UserInfo', 'created', 73, NULL, NULL, '{\"attributes\":{\"id\":73,\"user_id\":73,\"avatar\":null,\"company\":\"Ratke, Beatty and Cole\",\"phone\":\"(364) 738-5642\",\"website\":\"http:\\/\\/www.weimann.com\\/\",\"country\":\"SG\",\"language\":\"ee\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:27.000000Z\",\"updated_at\":\"2023-01-30T11:05:27.000000Z\"}}', NULL, '2023-01-30 05:05:27', '2023-01-30 05:05:27'),
(176, 'default', 'created', 'App\\Models\\UserInfo', 'created', 74, NULL, NULL, '{\"attributes\":{\"id\":74,\"user_id\":74,\"avatar\":null,\"company\":\"Hackett Ltd\",\"phone\":\"(201) 658-4511\",\"website\":\"http:\\/\\/www.roberts.com\\/amet-occaecati-temporibus-tempore-officiis-molestias-reprehenderit.html\",\"country\":\"NI\",\"language\":\"km\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:27.000000Z\",\"updated_at\":\"2023-01-30T11:05:27.000000Z\"}}', NULL, '2023-01-30 05:05:27', '2023-01-30 05:05:27'),
(177, 'default', 'created', 'App\\Models\\UserInfo', 'created', 75, NULL, NULL, '{\"attributes\":{\"id\":75,\"user_id\":75,\"avatar\":null,\"company\":\"Kuvalis LLC\",\"phone\":\"+1 (307) 840-2349\",\"website\":\"http:\\/\\/www.kuhlman.info\\/\",\"country\":\"BD\",\"language\":\"ks\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:27.000000Z\",\"updated_at\":\"2023-01-30T11:05:27.000000Z\"}}', NULL, '2023-01-30 05:05:27', '2023-01-30 05:05:27'),
(178, 'default', 'created', 'App\\Models\\UserInfo', 'created', 76, NULL, NULL, '{\"attributes\":{\"id\":76,\"user_id\":76,\"avatar\":null,\"company\":\"Morar PLC\",\"phone\":\"+1-281-268-0472\",\"website\":\"http:\\/\\/www.mcdermott.org\\/\",\"country\":\"JP\",\"language\":\"kv\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:27.000000Z\",\"updated_at\":\"2023-01-30T11:05:27.000000Z\"}}', NULL, '2023-01-30 05:05:27', '2023-01-30 05:05:27'),
(179, 'default', 'created', 'App\\Models\\UserInfo', 'created', 77, NULL, NULL, '{\"attributes\":{\"id\":77,\"user_id\":77,\"avatar\":null,\"company\":\"Sawayn Inc\",\"phone\":\"540.823.5176\",\"website\":\"http:\\/\\/lubowitz.biz\\/magnam-non-minima-sint-aut-vel-mollitia\",\"country\":\"BT\",\"language\":\"fo\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:27.000000Z\",\"updated_at\":\"2023-01-30T11:05:27.000000Z\"}}', NULL, '2023-01-30 05:05:27', '2023-01-30 05:05:27'),
(180, 'default', 'created', 'App\\Models\\UserInfo', 'created', 78, NULL, NULL, '{\"attributes\":{\"id\":78,\"user_id\":78,\"avatar\":null,\"company\":\"Schultz-Wisozk\",\"phone\":\"(313) 432-7541\",\"website\":\"https:\\/\\/www.hamill.com\\/earum-architecto-eius-magni-repellendus-facilis\",\"country\":\"TF\",\"language\":\"vo\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:27.000000Z\",\"updated_at\":\"2023-01-30T11:05:27.000000Z\"}}', NULL, '2023-01-30 05:05:27', '2023-01-30 05:05:27'),
(181, 'default', 'created', 'App\\Models\\UserInfo', 'created', 79, NULL, NULL, '{\"attributes\":{\"id\":79,\"user_id\":79,\"avatar\":null,\"company\":\"Donnelly, Will and Kshlerin\",\"phone\":\"+1 (612) 844-6864\",\"website\":\"http:\\/\\/oberbrunner.info\\/deserunt-nisi-debitis-omnis-minima-sint-est\",\"country\":\"ST\",\"language\":\"ss\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:27.000000Z\",\"updated_at\":\"2023-01-30T11:05:27.000000Z\"}}', NULL, '2023-01-30 05:05:27', '2023-01-30 05:05:27'),
(182, 'default', 'created', 'App\\Models\\UserInfo', 'created', 80, NULL, NULL, '{\"attributes\":{\"id\":80,\"user_id\":80,\"avatar\":null,\"company\":\"Kohler-Feeney\",\"phone\":\"+1-575-441-8828\",\"website\":\"http:\\/\\/www.hackett.biz\\/dignissimos-perferendis-dignissimos-repudiandae-dolorum-voluptatibus-tenetur-repellendus\",\"country\":\"CK\",\"language\":\"it\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:27.000000Z\",\"updated_at\":\"2023-01-30T11:05:27.000000Z\"}}', NULL, '2023-01-30 05:05:27', '2023-01-30 05:05:27'),
(183, 'default', 'created', 'App\\Models\\UserInfo', 'created', 81, NULL, NULL, '{\"attributes\":{\"id\":81,\"user_id\":81,\"avatar\":null,\"company\":\"Walker-Kiehn\",\"phone\":\"+1-908-471-6801\",\"website\":\"http:\\/\\/www.daugherty.biz\\/\",\"country\":\"QA\",\"language\":\"ty\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:27.000000Z\",\"updated_at\":\"2023-01-30T11:05:27.000000Z\"}}', NULL, '2023-01-30 05:05:28', '2023-01-30 05:05:28'),
(184, 'default', 'created', 'App\\Models\\UserInfo', 'created', 82, NULL, NULL, '{\"attributes\":{\"id\":82,\"user_id\":82,\"avatar\":null,\"company\":\"Koch, Klocko and Crooks\",\"phone\":\"1-248-533-6135\",\"website\":\"https:\\/\\/bednar.com\\/eveniet-voluptatibus-eos-cumque-et-aliquid-dolorem-autem-cupiditate.html\",\"country\":\"SN\",\"language\":\"eu\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:28.000000Z\",\"updated_at\":\"2023-01-30T11:05:28.000000Z\"}}', NULL, '2023-01-30 05:05:28', '2023-01-30 05:05:28');
INSERT INTO `activity_log` (`id`, `log_name`, `description`, `subject_type`, `event`, `subject_id`, `causer_type`, `causer_id`, `properties`, `batch_uuid`, `created_at`, `updated_at`) VALUES
(185, 'default', 'created', 'App\\Models\\UserInfo', 'created', 83, NULL, NULL, '{\"attributes\":{\"id\":83,\"user_id\":83,\"avatar\":null,\"company\":\"Parisian-Wilkinson\",\"phone\":\"(820) 313-9835\",\"website\":\"https:\\/\\/bartoletti.com\\/beatae-eveniet-et-fugit-nemo-cupiditate-quisquam.html\",\"country\":\"HN\",\"language\":\"ro\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:28.000000Z\",\"updated_at\":\"2023-01-30T11:05:28.000000Z\"}}', NULL, '2023-01-30 05:05:28', '2023-01-30 05:05:28'),
(186, 'default', 'created', 'App\\Models\\UserInfo', 'created', 84, NULL, NULL, '{\"attributes\":{\"id\":84,\"user_id\":84,\"avatar\":null,\"company\":\"Shields, Gleason and Hegmann\",\"phone\":\"1-425-566-5458\",\"website\":\"http:\\/\\/www.rohan.org\\/doloremque-modi-dolores-eum-pariatur-placeat-iste-iste-sint\",\"country\":\"SM\",\"language\":\"cs\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:28.000000Z\",\"updated_at\":\"2023-01-30T11:05:28.000000Z\"}}', NULL, '2023-01-30 05:05:28', '2023-01-30 05:05:28'),
(187, 'default', 'created', 'App\\Models\\UserInfo', 'created', 85, NULL, NULL, '{\"attributes\":{\"id\":85,\"user_id\":85,\"avatar\":null,\"company\":\"Legros, Haag and Mills\",\"phone\":\"(323) 616-3184\",\"website\":\"http:\\/\\/zieme.com\\/\",\"country\":\"IL\",\"language\":\"ff\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:28.000000Z\",\"updated_at\":\"2023-01-30T11:05:28.000000Z\"}}', NULL, '2023-01-30 05:05:28', '2023-01-30 05:05:28'),
(188, 'default', 'created', 'App\\Models\\UserInfo', 'created', 86, NULL, NULL, '{\"attributes\":{\"id\":86,\"user_id\":86,\"avatar\":null,\"company\":\"Prosacco, Little and Murray\",\"phone\":\"347.800.2252\",\"website\":\"http:\\/\\/www.hansen.com\\/\",\"country\":\"RS\",\"language\":\"uk\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:28.000000Z\",\"updated_at\":\"2023-01-30T11:05:28.000000Z\"}}', NULL, '2023-01-30 05:05:28', '2023-01-30 05:05:28'),
(189, 'default', 'created', 'App\\Models\\UserInfo', 'created', 87, NULL, NULL, '{\"attributes\":{\"id\":87,\"user_id\":87,\"avatar\":null,\"company\":\"Osinski Inc\",\"phone\":\"+14783423721\",\"website\":\"http:\\/\\/ziemann.biz\\/\",\"country\":\"BJ\",\"language\":\"ee\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:28.000000Z\",\"updated_at\":\"2023-01-30T11:05:28.000000Z\"}}', NULL, '2023-01-30 05:05:28', '2023-01-30 05:05:28'),
(190, 'default', 'created', 'App\\Models\\UserInfo', 'created', 88, NULL, NULL, '{\"attributes\":{\"id\":88,\"user_id\":88,\"avatar\":null,\"company\":\"Considine and Sons\",\"phone\":\"+1-216-701-3632\",\"website\":\"http:\\/\\/www.green.biz\\/animi-qui-doloribus-provident-recusandae-quia-quidem-inventore.html\",\"country\":\"AU\",\"language\":\"su\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:28.000000Z\",\"updated_at\":\"2023-01-30T11:05:28.000000Z\"}}', NULL, '2023-01-30 05:05:29', '2023-01-30 05:05:29'),
(191, 'default', 'created', 'App\\Models\\UserInfo', 'created', 89, NULL, NULL, '{\"attributes\":{\"id\":89,\"user_id\":89,\"avatar\":null,\"company\":\"Harvey, Flatley and Altenwerth\",\"phone\":\"1-567-483-5250\",\"website\":\"http:\\/\\/www.auer.com\\/ipsa-et-adipisci-fugiat-sint-doloremque-quos-reprehenderit.html\",\"country\":\"MC\",\"language\":\"hu\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:29.000000Z\",\"updated_at\":\"2023-01-30T11:05:29.000000Z\"}}', NULL, '2023-01-30 05:05:29', '2023-01-30 05:05:29'),
(192, 'default', 'created', 'App\\Models\\UserInfo', 'created', 90, NULL, NULL, '{\"attributes\":{\"id\":90,\"user_id\":90,\"avatar\":null,\"company\":\"Hirthe PLC\",\"phone\":\"608-294-0876\",\"website\":\"http:\\/\\/www.kemmer.com\\/quis-magni-voluptas-vel-molestias-tenetur.html\",\"country\":\"KE\",\"language\":\"uk\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:29.000000Z\",\"updated_at\":\"2023-01-30T11:05:29.000000Z\"}}', NULL, '2023-01-30 05:05:29', '2023-01-30 05:05:29'),
(193, 'default', 'created', 'App\\Models\\UserInfo', 'created', 91, NULL, NULL, '{\"attributes\":{\"id\":91,\"user_id\":91,\"avatar\":null,\"company\":\"Bartoletti-Hauck\",\"phone\":\"+1-612-539-4775\",\"website\":\"http:\\/\\/www.gislason.org\\/deserunt-consequuntur-commodi-et-in-voluptate.html\",\"country\":\"MN\",\"language\":\"tl\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:29.000000Z\",\"updated_at\":\"2023-01-30T11:05:29.000000Z\"}}', NULL, '2023-01-30 05:05:29', '2023-01-30 05:05:29'),
(194, 'default', 'created', 'App\\Models\\UserInfo', 'created', 92, NULL, NULL, '{\"attributes\":{\"id\":92,\"user_id\":92,\"avatar\":null,\"company\":\"Hermiston, Corkery and Cronin\",\"phone\":\"+19525242128\",\"website\":\"http:\\/\\/gottlieb.net\\/aliquid-ullam-enim-debitis-perspiciatis-nesciunt-necessitatibus-enim\",\"country\":\"AO\",\"language\":\"za\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:29.000000Z\",\"updated_at\":\"2023-01-30T11:05:29.000000Z\"}}', NULL, '2023-01-30 05:05:29', '2023-01-30 05:05:29'),
(195, 'default', 'created', 'App\\Models\\UserInfo', 'created', 93, NULL, NULL, '{\"attributes\":{\"id\":93,\"user_id\":93,\"avatar\":null,\"company\":\"Kuvalis, Keeling and Ullrich\",\"phone\":\"402.552.0885\",\"website\":\"http:\\/\\/www.pouros.biz\\/quia-repellendus-dolorem-vitae-deleniti\",\"country\":\"SM\",\"language\":\"sw\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:29.000000Z\",\"updated_at\":\"2023-01-30T11:05:29.000000Z\"}}', NULL, '2023-01-30 05:05:29', '2023-01-30 05:05:29'),
(196, 'default', 'created', 'App\\Models\\UserInfo', 'created', 94, NULL, NULL, '{\"attributes\":{\"id\":94,\"user_id\":94,\"avatar\":null,\"company\":\"Schmitt, Towne and Carter\",\"phone\":\"(410) 281-2156\",\"website\":\"http:\\/\\/reynolds.biz\\/commodi-rerum-deleniti-quaerat-aut-laboriosam-quia.html\",\"country\":\"HT\",\"language\":\"kl\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:29.000000Z\",\"updated_at\":\"2023-01-30T11:05:29.000000Z\"}}', NULL, '2023-01-30 05:05:29', '2023-01-30 05:05:29'),
(197, 'default', 'created', 'App\\Models\\UserInfo', 'created', 95, NULL, NULL, '{\"attributes\":{\"id\":95,\"user_id\":95,\"avatar\":null,\"company\":\"Williamson-Hane\",\"phone\":\"1-480-968-3427\",\"website\":\"https:\\/\\/jenkins.net\\/consectetur-quis-quasi-omnis-tenetur-cupiditate-in.html\",\"country\":\"PG\",\"language\":\"mn\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:29.000000Z\",\"updated_at\":\"2023-01-30T11:05:29.000000Z\"}}', NULL, '2023-01-30 05:05:29', '2023-01-30 05:05:29'),
(198, 'default', 'created', 'App\\Models\\UserInfo', 'created', 96, NULL, NULL, '{\"attributes\":{\"id\":96,\"user_id\":96,\"avatar\":null,\"company\":\"McGlynn-Donnelly\",\"phone\":\"440.371.9553\",\"website\":\"http:\\/\\/www.crist.biz\\/\",\"country\":\"LC\",\"language\":\"jv\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:29.000000Z\",\"updated_at\":\"2023-01-30T11:05:29.000000Z\"}}', NULL, '2023-01-30 05:05:30', '2023-01-30 05:05:30'),
(199, 'default', 'created', 'App\\Models\\UserInfo', 'created', 97, NULL, NULL, '{\"attributes\":{\"id\":97,\"user_id\":97,\"avatar\":null,\"company\":\"Schinner LLC\",\"phone\":\"380.336.9448\",\"website\":\"http:\\/\\/hauck.com\\/non-ratione-sapiente-maiores-aut\",\"country\":\"LI\",\"language\":\"ku\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:30.000000Z\",\"updated_at\":\"2023-01-30T11:05:30.000000Z\"}}', NULL, '2023-01-30 05:05:30', '2023-01-30 05:05:30'),
(200, 'default', 'created', 'App\\Models\\UserInfo', 'created', 98, NULL, NULL, '{\"attributes\":{\"id\":98,\"user_id\":98,\"avatar\":null,\"company\":\"Wilkinson, Nolan and Predovic\",\"phone\":\"+1-743-381-5031\",\"website\":\"http:\\/\\/www.spencer.org\\/expedita-molestiae-nulla-neque-accusantium-illo\",\"country\":\"GE\",\"language\":\"is\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:30.000000Z\",\"updated_at\":\"2023-01-30T11:05:30.000000Z\"}}', NULL, '2023-01-30 05:05:30', '2023-01-30 05:05:30'),
(201, 'default', 'created', 'App\\Models\\UserInfo', 'created', 99, NULL, NULL, '{\"attributes\":{\"id\":99,\"user_id\":99,\"avatar\":null,\"company\":\"Hegmann-Heathcote\",\"phone\":\"865-879-1534\",\"website\":\"http:\\/\\/runolfsson.com\\/maxime-laborum-voluptatum-totam-itaque-aspernatur-sed-illum.html\",\"country\":\"MN\",\"language\":\"gu\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:30.000000Z\",\"updated_at\":\"2023-01-30T11:05:30.000000Z\"}}', NULL, '2023-01-30 05:05:30', '2023-01-30 05:05:30'),
(202, 'default', 'created', 'App\\Models\\UserInfo', 'created', 100, NULL, NULL, '{\"attributes\":{\"id\":100,\"user_id\":100,\"avatar\":null,\"company\":\"Block, Daugherty and Lynch\",\"phone\":\"+1.364.915.1307\",\"website\":\"http:\\/\\/www.maggio.com\\/\",\"country\":\"SS\",\"language\":\"so\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:30.000000Z\",\"updated_at\":\"2023-01-30T11:05:30.000000Z\"}}', NULL, '2023-01-30 05:05:30', '2023-01-30 05:05:30'),
(203, 'default', 'created', 'App\\Models\\UserInfo', 'created', 101, NULL, NULL, '{\"attributes\":{\"id\":101,\"user_id\":101,\"avatar\":null,\"company\":\"Blick-Wiza\",\"phone\":\"+15019497591\",\"website\":\"http:\\/\\/www.klocko.net\\/\",\"country\":\"AI\",\"language\":\"oj\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:30.000000Z\",\"updated_at\":\"2023-01-30T11:05:30.000000Z\"}}', NULL, '2023-01-30 05:05:30', '2023-01-30 05:05:30'),
(204, 'default', 'created', 'App\\Models\\UserInfo', 'created', 102, NULL, NULL, '{\"attributes\":{\"id\":102,\"user_id\":102,\"avatar\":null,\"company\":\"Reichert LLC\",\"phone\":\"520-424-4966\",\"website\":\"https:\\/\\/oconnell.com\\/qui-quis-minus-et.html\",\"country\":\"BD\",\"language\":\"lv\",\"timezone\":null,\"currency\":null,\"communication\":null,\"marketing\":null,\"created_at\":\"2023-01-30T11:05:30.000000Z\",\"updated_at\":\"2023-01-30T11:05:30.000000Z\"}}', NULL, '2023-01-30 05:05:30', '2023-01-30 05:05:30'),
(205, 'default', 'created', 'App\\Models\\User', 'created', 103, NULL, NULL, '{\"attributes\":{\"id\":103,\"first_name\":\"MD\",\"last_name\":\"Masum\",\"email\":\"admin@masum.com\",\"email_verified_at\":null,\"password\":\"$2y$10$AfzXoCcyhMGbQnmKfBMOb.XjIEcEmIIFm7oA8T0CXSAKdl7btQwcG\",\"api_token\":null,\"remember_token\":null,\"created_at\":\"2023-01-31T09:59:20.000000Z\",\"updated_at\":\"2023-01-31T09:59:20.000000Z\"}}', NULL, '2023-01-31 03:59:20', '2023-01-31 03:59:20'),
(206, 'default', 'created', 'App\\Models\\UserInfo', 'created', 103, 'App\\Models\\User', 103, '{\"attributes\":{\"id\":103,\"user_id\":103,\"avatar\":\"images\\/m4QvXPPU5YcsWG4EOSVsQRBjI5eMIxL4CblmuFzN.png\",\"company\":null,\"phone\":\"016\",\"website\":null,\"country\":\"BD\",\"language\":\"en-gb\",\"timezone\":\"Dhaka\",\"currency\":null,\"communication\":{\"email\":\"1\",\"phone\":\"0\"},\"marketing\":0,\"created_at\":\"2023-01-31T10:05:00.000000Z\",\"updated_at\":\"2023-01-31T10:05:00.000000Z\"}}', NULL, '2023-01-31 04:05:00', '2023-01-31 04:05:00'),
(207, 'default', 'updated', 'App\\Models\\User', 'updated', 1, 'App\\Models\\User', 1, '{\"attributes\":{\"first_name\":\"GCL\",\"last_name\":\"Admin\",\"updated_at\":\"2023-01-31T10:56:45.000000Z\"},\"old\":{\"first_name\":\"MD\",\"last_name\":\"Masum\",\"updated_at\":\"2023-01-30T11:05:03.000000Z\"}}', NULL, '2023-01-31 04:56:45', '2023-01-31 04:56:45'),
(208, 'default', 'updated', 'App\\Models\\UserInfo', 'updated', 1, 'App\\Models\\User', 1, '{\"attributes\":{\"avatar\":\"images\\/DA6oVfAqPOcSR4AjGbo1TryIlKbWmthbgXhgCtpx.png\",\"language\":\"en-gb\",\"timezone\":\"Dhaka\",\"communication\":{\"email\":\"0\",\"phone\":\"0\"},\"marketing\":0,\"updated_at\":\"2023-01-31T10:56:45.000000Z\"},\"old\":{\"avatar\":null,\"language\":\"ik\",\"timezone\":null,\"communication\":null,\"marketing\":null,\"updated_at\":\"2023-01-30T11:05:03.000000Z\"}}', NULL, '2023-01-31 04:56:45', '2023-01-31 04:56:45'),
(209, 'default', 'created', 'App\\Models\\User', 'created', 104, NULL, NULL, '{\"attributes\":{\"id\":104,\"first_name\":\"Global\",\"last_name\":\"Admin\",\"email\":\"info@gslcorporate.com\",\"email_verified_at\":null,\"password\":\"$2y$10$OaFIVnac4qSoGiPY1ztUf.h7oNyGse1Ub9hGPrFEmVOnJIX5qTVye\",\"api_token\":null,\"remember_token\":null,\"created_at\":\"2023-01-31T12:24:50.000000Z\",\"updated_at\":\"2023-01-31T12:24:50.000000Z\"}}', NULL, '2023-01-31 06:24:50', '2023-01-31 06:24:50'),
(210, 'default', 'created', 'App\\Models\\UserInfo', 'created', 104, 'App\\Models\\User', 104, '{\"attributes\":{\"id\":104,\"user_id\":104,\"avatar\":\"images\\/8qtHFI0f9xOIss1lEz0Z62AGc3q3I5OyPrLF2ONx.png\",\"company\":null,\"phone\":\"01711 531786\",\"website\":null,\"country\":\"BD\",\"language\":\"en-gb\",\"timezone\":\"Dhaka\",\"currency\":null,\"communication\":{\"email\":\"0\",\"phone\":\"0\"},\"marketing\":0,\"created_at\":\"2023-01-31T12:27:48.000000Z\",\"updated_at\":\"2023-01-31T12:27:48.000000Z\"}}', NULL, '2023-01-31 06:27:48', '2023-01-31 06:27:48');

-- --------------------------------------------------------

--
-- Table structure for table `allowances`
--

CREATE TABLE `allowances` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `employee_id` int(11) NOT NULL,
  `allowance_option` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `amount` double(20,2) NOT NULL DEFAULT 0.00,
  `percentage` decimal(5,2) DEFAULT 0.00,
  `type` tinyint(4) DEFAULT 1,
  `created_by` int(11) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;

--
-- Dumping data for table `allowances`
--

INSERT INTO `allowances` (`id`, `employee_id`, `allowance_option`, `title`, `amount`, `percentage`, `type`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 1, 2, 'Allowance Title', 600.00, 1.00, 2, 1, '2023-07-19 07:49:26', '2023-07-19 10:31:04'),
(3, 1, 2, 'Allowance', 24000.00, 0.00, 1, 1, '2023-07-19 07:55:56', '2023-07-19 10:26:20'),
(4, 1, 2, 'Allowance Title', 18000.00, 30.00, 2, 1, '2023-07-19 10:19:18', '2023-07-19 10:28:23'),
(5, 2, 1, 'Allowance Title', 1500.00, 5.00, 2, 1, '2023-07-24 12:26:28', '2023-07-24 12:26:28');

-- --------------------------------------------------------

--
-- Table structure for table `allowance_options`
--

CREATE TABLE `allowance_options` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `status` tinyint(4) DEFAULT 1,
  `created_by` int(11) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;

--
-- Dumping data for table `allowance_options`
--

INSERT INTO `allowance_options` (`id`, `name`, `status`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 'Allowance Option 1', 1, 1, '2023-07-13 07:20:31', '2023-07-13 08:27:06'),
(2, 'Allowance Option 2', 1, 1, '2023-07-13 07:20:39', '2023-07-13 07:20:44');

-- --------------------------------------------------------

--
-- Table structure for table `announcements`
--

CREATE TABLE `announcements` (
  `id` int(20) UNSIGNED NOT NULL,
  `title` varchar(191) DEFAULT NULL,
  `start_date` date NOT NULL,
  `end_date` date DEFAULT NULL,
  `description` text DEFAULT NULL,
  `file_path` varchar(255) DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `announcements`
--

INSERT INTO `announcements` (`id`, `title`, `start_date`, `end_date`, `description`, `file_path`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 'New Announcement', '2023-12-16', '2023-12-17', 'Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin literature from 45 BC, making it over 2000 years old. Richard McClintock, a Latin professor at Hampden-Sydney College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage, and going through the cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum comes from sections 1.10.32 and 1.10.33 of \"de Finibus Bonorum et Malorum\" (The Extremes of Good and Evil) by Cicero, written in 45 BC. This book is a treatise on the theory of ethics, very popular during the Renaissance. The first line of Lorem Ipsum, \"Lorem ipsum dolor sit amet..\", comes from a line in section 1.10.32.', 'public/announcements/18-12-2023-11-19-18_Conveyance Bill.pdf', 1, '2023-12-18 05:19:18', '2023-12-18 05:19:18'),
(2, 'New Announcement 19-12-23', '2023-12-19', '2023-12-19', 'Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin literature from 45 BC, making it over 2000 years old. Richard McClintock, a Latin professor at Hampden-Sydney College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage, and going through the cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum comes from sections 1.10.32 and 1.10.33 of \"de Finibus Bonorum et Malorum\" (The Extremes of Good and Evil) by Cicero, written in 45 BC. This book is a treatise on the theory of ethics, very popular during the Renaissance. The first line of Lorem Ipsum, \"Lorem ipsum dolor sit amet..\", comes from a line in section 1.10.32.', 'public/announcements/18-12-2023-11-45-59_Conveyance Bill.pdf', 1, '2023-12-18 05:45:59', '2023-12-18 05:45:59'),
(3, 'New Announcement 18-12-23', '2023-12-18', '2023-12-18', 'Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin literature from 45 BC, making it over 2000 years old. Richard McClintock, a Latin professor at Hampden-Sydney College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage, and going through the cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum comes from sections 1.10.32 and 1.10.33 of \"de Finibus Bonorum et Malorum\" (The Extremes of Good and Evil) by Cicero, written in 45 BC. This book is a treatise on the theory of ethics, very popular during the Renaissance. The first line of Lorem Ipsum, \"Lorem ipsum dolor sit amet..\", comes from a line in section 1.10.32.', 'public/announcements/18-12-2023-11-47-03_Conveyance Bill.jpg', 1, '2023-12-18 05:47:03', '2023-12-18 05:47:03'),
(4, 'New Announcement 1010', '2023-12-18', '2023-12-31', 'It is a long established fact that a reader will be distracted by the readable content of a page when looking at its layout. The point of using Lorem Ipsum is that it has a more-or-less normal distribution of letters, as opposed to using \'Content here, content here\', making it look like readable English. Many desktop publishing packages and web page editors now use Lorem Ipsum as their default model text, and a search for \'lorem ipsum\' will uncover many web sites still in their infancy. Various versions have evolved over the years, sometimes by accident, sometimes on purpose (injected humour and the like).', 'public/announcements/19-12-2023-07-04-36_Conveyance Bill.pdf', 1, '2023-12-19 01:04:36', '2023-12-19 01:04:36'),
(6, '25 Dec', '2023-12-24', '2023-12-25', 'Holiday 25 dec 2023', NULL, 1, '2023-12-24 01:38:42', '2023-12-24 01:38:42');

-- --------------------------------------------------------

--
-- Table structure for table `announcement_details`
--

CREATE TABLE `announcement_details` (
  `id` bigint(20) NOT NULL,
  `announcement_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `status` tinyint(4) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `announcement_details`
--

INSERT INTO `announcement_details` (`id`, `announcement_id`, `employee_id`, `status`) VALUES
(1, 1, 3, 1),
(2, 1, 5, 1),
(3, 1, 6, 1),
(4, 1, 9, 1),
(5, 1, 10, 1),
(6, 1, 12, 1),
(7, 1, 14, 1),
(8, 1, 16, 1),
(9, 2, 3, 1),
(10, 2, 5, 1),
(11, 2, 6, 1),
(12, 2, 9, 1),
(13, 2, 10, 1),
(14, 2, 12, 1),
(15, 2, 14, 1),
(16, 2, 16, 1),
(17, 3, 3, 1),
(18, 3, 5, 1),
(19, 3, 6, 1),
(20, 3, 9, 1),
(21, 3, 10, 1),
(22, 3, 12, 1),
(23, 3, 14, 1),
(24, 3, 16, 1),
(25, 4, 3, 1),
(26, 4, 5, 1),
(27, 4, 6, 1),
(28, 4, 9, 1),
(29, 4, 10, 1),
(30, 4, 12, 1),
(31, 4, 14, 1),
(32, 4, 16, 1),
(41, 6, 3, 1),
(42, 6, 5, 1),
(43, 6, 6, 1),
(44, 6, 1, 1),
(45, 6, 2, 1),
(46, 6, 4, 1);

-- --------------------------------------------------------

--
-- Table structure for table `attendances`
--

CREATE TABLE `attendances` (
  `id` bigint(20) NOT NULL,
  `machine_id` int(11) DEFAULT NULL,
  `employee_code` int(11) DEFAULT NULL,
  `date_time_record` datetime DEFAULT NULL,
  `date_only_record` date DEFAULT NULL,
  `done_by` varchar(150) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `attendances`
--

INSERT INTO `attendances` (`id`, `machine_id`, `employee_code`, `date_time_record`, `date_only_record`, `done_by`, `created_at`, `updated_at`) VALUES
(1, 1, 1, '2023-10-04 11:56:51', '2023-10-04', NULL, '2023-10-04 12:08:01', NULL),
(2, 1, 1, '2023-10-04 11:57:08', '2023-10-04', NULL, '2023-10-04 12:08:01', NULL),
(3, 1, 1, '2023-10-04 12:17:34', '2023-10-04', NULL, '2023-10-04 12:08:01', NULL),
(4, 1, 1, '2023-10-04 12:44:11', '2023-10-04', NULL, '2023-10-04 12:08:01', NULL),
(5, 1, 1, '2023-10-04 12:44:38', '2023-10-04', NULL, '2023-10-04 12:08:01', NULL),
(6, 1, 1, '2023-10-04 12:44:50', '2023-10-04', NULL, '2023-10-04 12:08:01', NULL),
(7, 1, 1, '2023-10-04 12:56:45', '2023-10-04', NULL, '2023-10-04 12:08:01', NULL),
(8, 1, 1, '2023-10-04 12:56:51', '2023-10-04', NULL, '2023-10-04 12:08:01', NULL),
(9, 1, 1, '2023-10-04 13:14:40', '2023-10-04', NULL, '2023-10-04 12:08:01', NULL),
(10, 1, 1, '2023-10-04 13:17:06', '2023-10-04', NULL, '2023-10-04 12:08:01', NULL),
(11, 1, 1, '2023-10-04 13:17:14', '2023-10-04', NULL, '2023-10-04 12:08:01', NULL),
(12, 1, 1, '2023-10-04 13:20:41', '2023-10-04', NULL, '2023-10-04 12:08:01', NULL),
(13, 1, 1, '2023-10-04 13:20:42', '2023-10-04', NULL, '2023-10-04 12:08:01', NULL),
(14, 1, 1, '2023-10-04 13:35:25', '2023-10-04', NULL, '2023-10-04 12:08:01', NULL),
(15, 1, 1, '2023-10-04 13:35:40', '2023-10-04', NULL, '2023-10-04 12:08:01', NULL),
(16, 1, 1, '2023-10-04 13:35:51', '2023-10-04', NULL, '2023-10-04 12:08:02', NULL),
(17, 1, 1, '2023-10-04 13:36:45', '2023-10-04', NULL, '2023-10-04 12:08:02', NULL),
(18, 1, 1, '2023-10-04 13:37:57', '2023-10-04', NULL, '2023-10-04 12:08:02', NULL),
(19, 1, 1, '2023-10-04 16:22:38', '2023-10-04', NULL, '2023-10-04 12:08:02', NULL),
(20, 1, 1, '2023-10-04 16:23:06', '2023-10-04', NULL, '2023-10-04 12:08:02', NULL),
(21, 1, 1, '2023-10-04 16:23:19', '2023-10-04', NULL, '2023-10-04 12:08:02', NULL),
(22, 1, 1, '2023-10-04 16:34:24', '2023-10-04', NULL, '2023-10-04 12:08:02', NULL),
(23, 1, 1, '2023-10-04 16:43:25', '2023-10-04', NULL, '2023-10-04 12:08:02', NULL),
(24, 1, 1, '2023-09-07 13:51:10', '2023-09-07', NULL, '2023-10-04 12:08:03', NULL),
(25, 1, 1, '2023-09-07 13:51:43', '2023-09-07', NULL, '2023-10-04 12:08:03', NULL),
(26, 1, 1, '2023-09-07 13:51:47', '2023-09-07', NULL, '2023-10-04 12:08:03', NULL),
(27, 1, 1, '2023-09-07 13:51:49', '2023-09-07', NULL, '2023-10-04 12:08:03', NULL),
(28, 1, 1, '2023-09-07 13:53:45', '2023-09-07', NULL, '2023-10-04 12:08:03', NULL),
(29, 1, 1, '2023-09-07 15:02:34', '2023-09-07', NULL, '2023-10-04 12:08:03', NULL),
(30, 1, 1, '2023-09-07 15:02:37', '2023-09-07', NULL, '2023-10-04 12:08:03', NULL),
(31, 1, 1, '2023-09-07 15:02:43', '2023-09-07', NULL, '2023-10-04 12:08:03', NULL),
(32, 1, 1, '2023-09-07 15:02:48', '2023-09-07', NULL, '2023-10-04 12:08:03', NULL),
(33, 1, 1, '2023-09-07 15:02:53', '2023-09-07', NULL, '2023-10-04 12:08:03', NULL),
(34, 1, 1, '2023-09-07 15:07:02', '2023-09-07', NULL, '2023-10-04 12:08:03', NULL),
(35, 1, 1, '2023-09-07 15:27:50', '2023-09-07', NULL, '2023-10-04 12:08:03', NULL),
(36, 1, 1, '2023-09-07 15:27:53', '2023-09-07', NULL, '2023-10-04 12:08:03', NULL),
(37, 1, 1, '2023-09-07 15:27:55', '2023-09-07', NULL, '2023-10-04 12:08:03', NULL),
(38, 1, 1, '2023-09-07 15:27:56', '2023-09-07', NULL, '2023-10-04 12:08:03', NULL),
(39, 1, 1, '2023-09-07 15:27:57', '2023-09-07', NULL, '2023-10-04 12:08:03', NULL),
(40, 1, 1, '2023-09-07 15:27:58', '2023-09-07', NULL, '2023-10-04 12:08:03', NULL),
(41, 1, 1, '2023-09-07 15:27:59', '2023-09-07', NULL, '2023-10-04 12:08:03', NULL),
(42, 1, 1, '2023-09-07 15:28:01', '2023-09-07', NULL, '2023-10-04 12:08:03', NULL),
(43, 1, 2, '2023-09-07 09:35:35', '2023-09-07', NULL, '2023-10-04 12:08:03', NULL),
(44, 1, 1, '2023-09-07 15:35:50', '2023-09-07', NULL, '2023-10-04 12:08:03', NULL),
(45, 1, 2, '2023-09-07 15:35:53', '2023-09-07', NULL, '2023-10-04 12:08:03', NULL),
(46, 1, 1, '2023-09-07 16:01:34', '2023-09-07', NULL, '2023-10-04 12:08:03', NULL),
(47, 1, 1, '2023-09-07 16:14:29', '2023-09-07', NULL, '2023-10-04 12:08:03', NULL),
(48, 1, 1, '2023-09-07 16:17:00', '2023-09-07', NULL, '2023-10-04 12:08:03', NULL),
(49, 1, 1, '2023-09-07 17:15:23', '2023-09-07', NULL, '2023-10-04 12:08:03', NULL),
(50, 1, 1, '2023-09-07 17:42:34', '2023-09-07', NULL, '2023-10-04 12:08:03', NULL),
(51, 1, 1, '2023-09-07 18:13:02', '2023-09-07', NULL, '2023-10-04 12:08:04', NULL),
(52, 1, 1, '2023-09-07 18:13:04', '2023-09-07', NULL, '2023-10-04 12:08:04', NULL),
(53, 1, 1, '2023-09-07 18:30:20', '2023-09-07', NULL, '2023-10-04 12:08:04', NULL),
(54, 1, 1, '2023-09-07 18:30:25', '2023-09-07', NULL, '2023-10-04 12:08:04', NULL),
(55, 1, 1, '2023-09-07 18:32:08', '2023-09-07', NULL, '2023-10-04 12:08:04', NULL),
(56, 1, 1, '2023-09-07 18:32:11', '2023-09-07', NULL, '2023-10-04 12:08:04', NULL),
(57, 1, 1, '2023-09-07 18:32:14', '2023-09-07', NULL, '2023-10-04 12:08:04', NULL),
(58, 1, 1, '2023-09-10 10:55:03', '2023-09-10', NULL, '2023-10-04 12:08:04', NULL),
(59, 1, 1, '2023-09-10 10:55:19', '2023-09-10', NULL, '2023-10-04 12:08:04', NULL),
(60, 1, 1, '2023-09-10 10:56:32', '2023-09-10', NULL, '2023-10-04 12:08:04', NULL),
(61, 1, 1, '2023-09-10 10:56:36', '2023-09-10', NULL, '2023-10-04 12:08:04', NULL),
(62, 1, 1, '2023-09-10 10:56:38', '2023-09-10', NULL, '2023-10-04 12:08:04', NULL),
(63, 1, 1, '2023-09-10 10:56:40', '2023-09-10', NULL, '2023-10-04 12:08:04', NULL),
(64, 1, 1, '2023-09-10 11:17:03', '2023-09-10', NULL, '2023-10-04 12:08:04', NULL),
(65, 1, 1, '2023-09-10 11:17:04', '2023-09-10', NULL, '2023-10-04 12:08:04', NULL),
(66, 1, 1, '2023-09-10 11:17:15', '2023-09-10', NULL, '2023-10-04 12:08:04', NULL),
(67, 1, 1, '2023-09-10 11:38:47', '2023-09-10', NULL, '2023-10-04 12:08:04', NULL),
(68, 1, 2, '2023-09-10 12:55:00', '2023-09-10', NULL, '2023-10-04 12:08:04', NULL),
(69, 1, 1, '2023-09-10 13:34:07', '2023-09-10', NULL, '2023-10-04 12:08:04', NULL),
(70, 1, 1, '2023-09-10 13:35:04', '2023-09-10', NULL, '2023-10-04 12:08:04', NULL),
(71, 1, 1, '2023-09-10 13:35:23', '2023-09-10', NULL, '2023-10-04 12:08:04', NULL),
(73, 1, 1, '2023-09-10 15:28:15', '2023-09-10', NULL, '2023-10-04 12:08:04', NULL),
(74, 1, 1, '2023-09-10 18:05:50', '2023-09-10', NULL, '2023-10-04 12:08:04', NULL),
(75, 1, 1, '2023-09-10 18:06:46', '2023-09-10', NULL, '2023-10-04 12:08:04', NULL),
(76, 1, 1, '2023-09-10 18:15:46', '2023-09-10', NULL, '2023-10-04 12:08:05', NULL),
(77, 1, 1, '2023-09-10 18:18:57', '2023-09-10', NULL, '2023-10-04 12:08:05', NULL),
(78, 1, 1, '2023-09-10 18:24:08', '2023-09-10', NULL, '2023-10-04 12:08:05', NULL),
(79, 1, 1, '2023-09-10 18:35:32', '2023-09-10', NULL, '2023-10-04 12:08:05', NULL),
(80, 1, 1, '2023-09-10 18:42:16', '2023-09-10', NULL, '2023-10-04 12:08:05', NULL),
(81, 1, 1, '2023-09-11 12:19:18', '2023-09-11', NULL, '2023-10-04 12:08:05', NULL),
(82, 1, 1, '2023-09-11 12:19:27', '2023-09-11', NULL, '2023-10-04 12:08:05', NULL),
(83, 1, 1, '2023-09-11 12:24:56', '2023-09-11', NULL, '2023-10-04 12:08:05', NULL),
(84, 1, 1, '2023-09-11 12:24:58', '2023-09-11', NULL, '2023-10-04 12:08:05', NULL),
(85, 1, 1, '2023-09-11 12:26:35', '2023-09-11', NULL, '2023-10-04 12:08:05', NULL),
(86, 1, 1, '2023-09-11 12:27:38', '2023-09-11', NULL, '2023-10-04 12:08:05', NULL),
(87, 1, 1, '2023-09-11 12:32:47', '2023-09-11', NULL, '2023-10-04 12:08:05', NULL),
(88, 1, 1, '2023-09-11 12:32:54', '2023-09-11', NULL, '2023-10-04 12:08:05', NULL),
(89, 1, 2, '2023-09-11 12:32:59', '2023-09-11', NULL, '2023-10-04 12:08:05', NULL),
(90, 1, 1, '2023-09-11 12:45:46', '2023-09-11', NULL, '2023-10-04 12:08:05', NULL),
(91, 1, 1, '2023-09-11 12:46:23', '2023-09-11', NULL, '2023-10-04 12:08:05', NULL),
(92, 1, 1, '2023-09-11 12:46:27', '2023-09-11', NULL, '2023-10-04 12:08:05', NULL),
(93, 1, 1, '2023-09-11 12:46:30', '2023-09-11', NULL, '2023-10-04 12:08:05', NULL),
(94, 1, 1, '2023-09-11 13:03:38', '2023-09-11', NULL, '2023-10-04 12:08:05', NULL),
(95, 1, 2, '2023-09-11 13:06:16', '2023-09-11', NULL, '2023-10-04 12:08:05', NULL),
(96, 1, 2, '2023-09-11 13:07:07', '2023-09-11', NULL, '2023-10-04 12:08:05', NULL),
(97, 1, 2, '2023-09-11 13:07:42', '2023-09-11', NULL, '2023-10-04 12:08:05', NULL),
(99, 1, 1, '2023-09-11 17:07:41', '2023-09-11', NULL, '2023-10-04 12:08:05', NULL),
(100, 1, 1, '2023-09-11 17:07:43', '2023-09-11', NULL, '2023-10-04 12:08:05', NULL),
(101, 1, 1, '2023-09-11 17:07:46', '2023-09-11', NULL, '2023-10-04 12:08:05', NULL),
(102, 1, 1, '2023-09-11 17:23:49', '2023-09-11', NULL, '2023-10-04 12:08:06', NULL),
(103, 1, 1, '2023-09-11 17:24:02', '2023-09-11', NULL, '2023-10-04 12:08:06', NULL),
(104, 1, 1, '2023-09-11 17:37:56', '2023-09-11', NULL, '2023-10-04 12:08:06', NULL),
(105, 1, 1, '2023-09-11 18:15:34', '2023-09-11', NULL, '2023-10-04 12:08:06', NULL),
(106, 1, 1, '2023-09-11 18:16:31', '2023-09-11', NULL, '2023-10-04 12:08:06', NULL),
(107, 1, 1, '2023-09-13 13:30:22', '2023-09-13', NULL, '2023-10-04 12:08:06', NULL),
(108, 1, 1, '2023-09-13 13:30:24', '2023-09-13', NULL, '2023-10-04 12:08:06', NULL),
(109, 1, 1, '2023-09-13 15:39:34', '2023-09-13', NULL, '2023-10-04 12:08:06', NULL),
(110, 1, 1, '2023-09-13 15:39:45', '2023-09-13', NULL, '2023-10-04 12:08:06', NULL),
(111, 1, 1, '2023-09-13 16:22:45', '2023-09-13', NULL, '2023-10-04 12:08:06', NULL),
(112, 1, 2, '2023-09-13 16:50:03', '2023-09-13', NULL, '2023-10-04 12:08:06', NULL),
(113, 1, 1, '2023-09-13 16:55:40', '2023-09-13', NULL, '2023-10-04 12:08:06', NULL),
(114, 1, 1, '2023-09-13 17:41:48', '2023-09-13', NULL, '2023-10-04 12:08:06', NULL),
(115, 1, 1, '2023-09-13 17:41:50', '2023-09-13', NULL, '2023-10-04 12:08:06', NULL),
(116, 1, 1, '2023-09-13 17:41:51', '2023-09-13', NULL, '2023-10-04 12:08:06', NULL),
(117, 1, 1, '2023-09-13 17:49:50', '2023-09-13', NULL, '2023-10-04 12:08:06', NULL),
(118, 1, 1, '2023-09-13 17:49:53', '2023-09-13', NULL, '2023-10-04 12:08:06', NULL),
(119, 1, 1, '2023-09-13 17:56:33', '2023-09-13', NULL, '2023-10-04 12:08:06', NULL),
(120, 1, 1, '2023-09-13 17:56:44', '2023-09-13', NULL, '2023-10-04 12:08:06', NULL),
(121, 1, 1, '2023-09-13 18:27:15', '2023-09-13', NULL, '2023-10-04 12:08:06', NULL),
(122, 1, 1, '2023-09-13 18:27:33', '2023-09-13', NULL, '2023-10-04 12:08:06', NULL),
(123, 1, 1, '2023-09-13 18:27:34', '2023-09-13', NULL, '2023-10-04 12:08:06', NULL),
(124, 1, 1, '2023-09-13 18:27:43', '2023-09-13', NULL, '2023-10-04 12:08:06', NULL),
(125, 1, 1, '2023-09-13 18:27:47', '2023-09-13', NULL, '2023-10-04 12:08:06', NULL),
(126, 1, 1, '2023-09-13 18:31:10', '2023-09-13', NULL, '2023-10-04 12:08:06', NULL),
(127, 1, 1, '2023-09-13 18:49:40', '2023-09-13', NULL, '2023-10-04 12:08:06', NULL),
(128, 1, 1, '2023-09-13 18:49:41', '2023-09-13', NULL, '2023-10-04 12:08:06', NULL),
(129, 1, 1, '2023-09-14 14:52:14', '2023-09-14', NULL, '2023-10-04 12:08:07', NULL),
(130, 1, 2, '2023-09-14 15:06:34', '2023-09-14', NULL, '2023-10-04 12:08:07', NULL),
(131, 1, 1, '2023-09-14 16:01:24', '2023-09-14', NULL, '2023-10-04 12:08:07', NULL),
(132, 1, 1, '2023-09-17 11:12:43', '2023-09-17', NULL, '2023-10-04 12:08:07', NULL),
(133, 1, 1, '2023-09-17 11:16:46', '2023-09-17', NULL, '2023-10-04 12:08:07', NULL),
(134, 1, 2, '2023-09-17 11:17:01', '2023-09-17', NULL, '2023-10-04 12:08:07', NULL),
(135, 1, 1, '2023-09-17 11:38:08', '2023-09-17', NULL, '2023-10-04 12:08:07', NULL),
(136, 1, 1, '2023-09-17 12:04:56', '2023-09-17', NULL, '2023-10-04 12:08:07', NULL),
(137, 1, 1, '2023-09-17 12:31:06', '2023-09-17', NULL, '2023-10-04 12:08:07', NULL),
(138, 1, 1, '2023-09-17 12:31:10', '2023-09-17', NULL, '2023-10-04 12:08:07', NULL),
(139, 1, 1, '2023-09-17 12:31:12', '2023-09-17', NULL, '2023-10-04 12:08:07', NULL),
(140, 1, 1, '2023-09-17 12:31:16', '2023-09-17', NULL, '2023-10-04 12:08:07', NULL),
(141, 1, 1, '2023-09-17 12:31:18', '2023-09-17', NULL, '2023-10-04 12:08:07', NULL),
(142, 1, 1, '2023-09-17 12:31:19', '2023-09-17', NULL, '2023-10-04 12:08:07', NULL),
(143, 1, 1, '2023-09-17 12:31:20', '2023-09-17', NULL, '2023-10-04 12:08:07', NULL),
(144, 1, 1, '2023-09-17 12:31:22', '2023-09-17', NULL, '2023-10-04 12:08:07', NULL),
(145, 1, 1, '2023-09-17 12:31:23', '2023-09-17', NULL, '2023-10-04 12:08:07', NULL),
(146, 1, 1, '2023-09-17 12:31:26', '2023-09-17', NULL, '2023-10-04 12:08:07', NULL),
(147, 1, 1, '2023-09-17 12:31:27', '2023-09-17', NULL, '2023-10-04 12:08:07', NULL),
(148, 1, 1, '2023-09-17 12:31:29', '2023-09-17', NULL, '2023-10-04 12:08:07', NULL),
(149, 1, 1, '2023-09-17 13:41:32', '2023-09-17', NULL, '2023-10-04 12:08:07', NULL),
(150, 1, 1, '2023-09-17 13:41:33', '2023-09-17', NULL, '2023-10-04 12:08:07', NULL),
(151, 1, 1, '2023-09-17 13:41:34', '2023-09-17', NULL, '2023-10-04 12:08:07', NULL),
(152, 1, 1, '2023-09-17 13:41:36', '2023-09-17', NULL, '2023-10-04 12:08:07', NULL),
(153, 1, 1, '2023-09-17 13:41:37', '2023-09-17', NULL, '2023-10-04 12:08:07', NULL),
(154, 1, 1, '2023-09-17 13:41:40', '2023-09-17', NULL, '2023-10-04 12:08:08', NULL),
(155, 1, 1, '2023-09-17 13:41:41', '2023-09-17', NULL, '2023-10-04 12:08:08', NULL),
(156, 1, 1, '2023-09-17 13:41:43', '2023-09-17', NULL, '2023-10-04 12:08:08', NULL),
(157, 1, 1, '2023-09-17 13:41:44', '2023-09-17', NULL, '2023-10-04 12:08:08', NULL),
(158, 1, 1, '2023-09-17 13:41:45', '2023-09-17', NULL, '2023-10-04 12:08:08', NULL),
(159, 1, 1, '2023-09-17 13:41:46', '2023-09-17', NULL, '2023-10-04 12:08:08', NULL),
(160, 1, 1, '2023-09-17 13:41:48', '2023-09-17', NULL, '2023-10-04 12:08:08', NULL),
(161, 1, 1, '2023-09-17 13:41:49', '2023-09-17', NULL, '2023-10-04 12:08:08', NULL),
(162, 1, 1, '2023-09-17 13:44:12', '2023-09-17', NULL, '2023-10-04 12:08:08', NULL),
(163, 1, 1, '2023-09-17 13:44:14', '2023-09-17', NULL, '2023-10-04 12:08:08', NULL),
(164, 1, 1, '2023-09-17 16:04:32', '2023-09-17', NULL, '2023-10-04 12:08:08', NULL),
(165, 1, 1, '2023-09-17 16:12:03', '2023-09-17', NULL, '2023-10-04 12:08:08', NULL),
(167, 1, 1, '2023-09-17 16:22:25', '2023-09-17', NULL, '2023-10-04 12:08:08', NULL),
(168, 1, 1, '2023-09-17 16:28:47', '2023-09-17', NULL, '2023-10-04 12:08:08', NULL),
(169, 1, 1, '2023-09-17 16:29:15', '2023-09-17', NULL, '2023-10-04 12:08:08', NULL),
(170, 1, 1, '2023-09-17 16:33:22', '2023-09-17', NULL, '2023-10-04 12:08:08', NULL),
(171, 1, 1, '2023-09-17 16:35:39', '2023-09-17', NULL, '2023-10-04 12:08:09', NULL),
(172, 1, 1, '2023-09-17 16:37:26', '2023-09-17', NULL, '2023-10-04 12:08:09', NULL),
(173, 1, 1, '2023-09-17 16:40:58', '2023-09-17', NULL, '2023-10-04 12:08:09', NULL),
(174, 1, 1, '2023-09-17 17:05:39', '2023-09-17', NULL, '2023-10-04 12:08:09', NULL),
(175, 1, 1, '2023-09-17 17:05:56', '2023-09-17', NULL, '2023-10-04 12:08:09', NULL),
(176, 1, 1, '2023-09-17 17:08:35', '2023-09-17', NULL, '2023-10-04 12:08:09', NULL),
(177, 1, 1, '2023-09-17 17:10:04', '2023-09-17', NULL, '2023-10-04 12:08:09', NULL),
(178, 1, 1, '2023-09-17 17:10:28', '2023-09-17', NULL, '2023-10-04 12:08:09', NULL),
(179, 1, 1, '2023-09-17 17:13:19', '2023-09-17', NULL, '2023-10-04 12:08:09', NULL),
(180, 1, 1, '2023-09-17 17:14:27', '2023-09-17', NULL, '2023-10-04 12:08:09', NULL),
(181, 1, 1, '2023-09-17 17:14:28', '2023-09-17', NULL, '2023-10-04 12:08:09', NULL),
(182, 1, 1, '2023-09-17 17:14:29', '2023-09-17', NULL, '2023-10-04 12:08:09', NULL),
(183, 1, 1, '2023-09-17 17:14:30', '2023-09-17', NULL, '2023-10-04 12:08:09', NULL),
(184, 1, 1, '2023-09-17 17:14:31', '2023-09-17', NULL, '2023-10-04 12:08:09', NULL),
(185, 1, 1, '2023-09-17 17:14:33', '2023-09-17', NULL, '2023-10-04 12:08:10', NULL),
(186, 1, 1, '2023-09-17 17:14:34', '2023-09-17', NULL, '2023-10-04 12:08:10', NULL),
(187, 1, 2, '2023-09-17 17:22:22', '2023-09-17', NULL, '2023-10-04 12:08:10', NULL),
(188, 1, 1, '2023-09-18 10:56:46', '2023-09-18', NULL, '2023-10-04 12:08:10', NULL),
(189, 1, 1, '2023-09-18 11:09:28', '2023-09-18', NULL, '2023-10-04 12:08:10', NULL),
(190, 1, 2, '2023-09-18 11:18:56', '2023-09-18', NULL, '2023-10-04 12:08:10', NULL),
(191, 1, 1, '2023-09-18 12:24:39', '2023-09-18', NULL, '2023-10-04 12:08:10', NULL),
(192, 1, 1, '2023-09-18 13:18:20', '2023-09-18', NULL, '2023-10-04 12:08:10', NULL),
(193, 1, 1, '2023-09-18 13:19:07', '2023-09-18', NULL, '2023-10-04 12:08:10', NULL),
(194, 1, 1, '2023-09-18 13:20:21', '2023-09-18', NULL, '2023-10-04 12:08:10', NULL),
(195, 1, 1, '2023-09-20 16:12:15', '2023-09-20', NULL, '2023-10-04 12:08:10', NULL),
(196, 1, 1, '2023-09-20 16:13:35', '2023-09-20', NULL, '2023-10-04 12:08:10', NULL),
(197, 1, 1, '2023-09-20 16:14:51', '2023-09-20', NULL, '2023-10-04 12:08:10', NULL),
(198, 1, 1, '2023-09-20 16:15:02', '2023-09-20', NULL, '2023-10-04 12:08:10', NULL),
(199, 1, 1, '2023-09-20 16:15:03', '2023-09-20', NULL, '2023-10-04 12:08:10', NULL),
(200, 1, 1, '2023-09-20 16:15:06', '2023-09-20', NULL, '2023-10-04 12:08:10', NULL),
(201, 1, 1, '2023-09-20 16:15:07', '2023-09-20', NULL, '2023-10-04 12:08:10', NULL),
(202, 1, 1, '2023-09-20 16:15:10', '2023-09-20', NULL, '2023-10-04 12:08:10', NULL),
(203, 1, 1, '2023-09-20 16:31:24', '2023-09-20', NULL, '2023-10-04 12:08:10', NULL),
(205, 1, 1, '2023-09-27 17:33:14', '2023-09-27', NULL, '2023-10-04 12:08:10', NULL),
(206, 1, 1, '2023-09-27 17:36:01', '2023-09-27', NULL, '2023-10-04 12:08:10', NULL),
(207, 1, 1, '2023-09-27 17:36:09', '2023-09-27', NULL, '2023-10-04 12:08:10', NULL),
(208, 1, 1, '2023-09-27 17:48:33', '2023-09-27', NULL, '2023-10-04 12:08:10', NULL),
(255, 1, 1, '2023-10-04 18:08:31', '2023-10-04', NULL, '2023-10-04 12:08:43', NULL),
(280, 1, 1, '2023-10-04 18:11:05', '2023-10-04', NULL, '2023-10-04 12:11:16', NULL),
(361, 1, 1, '2023-10-09 13:48:47', '2023-10-09', NULL, '2023-10-09 08:16:09', NULL),
(362, 1, 1, '2023-10-09 13:54:07', '2023-10-09', NULL, '2023-10-09 08:16:09', NULL),
(363, 1, 1, '2023-10-09 13:56:47', '2023-10-09', NULL, '2023-10-09 08:16:09', NULL),
(364, 1, 1, '2023-10-09 13:57:57', '2023-10-09', NULL, '2023-10-09 08:16:09', NULL),
(365, 1, 1, '2023-10-09 13:57:58', '2023-10-09', NULL, '2023-10-09 08:16:09', NULL),
(366, 1, 1, '2023-10-09 14:07:04', '2023-10-09', NULL, '2023-10-09 08:16:09', NULL),
(367, 1, 1, '2023-10-09 14:07:05', '2023-10-09', NULL, '2023-10-09 08:16:09', NULL),
(368, 1, 1, '2023-10-09 14:07:07', '2023-10-09', NULL, '2023-10-09 08:16:09', NULL),
(369, 1, 1, '2023-10-09 14:07:09', '2023-10-09', NULL, '2023-10-09 08:16:09', NULL),
(406, 1, 1, '2023-10-09 14:17:18', '2023-10-09', NULL, '2023-10-09 08:17:34', NULL),
(823, 1, 1, '2023-10-09 16:47:22', '2023-10-09', NULL, '2023-10-11 11:33:05', NULL),
(824, 1, 1, '2023-10-09 17:24:04', '2023-10-09', NULL, '2023-10-11 11:33:05', NULL),
(825, 1, 1, '2023-10-09 17:50:19', '2023-10-09', NULL, '2023-10-11 11:33:05', NULL),
(826, 1, 2, '2023-10-11 17:21:04', '2023-10-11', NULL, '2023-10-11 11:33:05', NULL),
(827, 1, 1, '2023-10-11 17:21:08', '2023-10-11', NULL, '2023-10-11 11:33:05', NULL),
(828, 1, 1, '2023-10-11 17:21:10', '2023-10-11', NULL, '2023-10-11 11:33:05', NULL),
(829, 1, 2, '2023-10-11 17:21:13', '2023-10-11', NULL, '2023-10-11 11:33:05', NULL),
(830, 1, 2, '2023-10-11 17:21:41', '2023-10-11', NULL, '2023-10-11 11:33:05', NULL),
(831, 1, 1, '2023-10-11 17:21:44', '2023-10-11', NULL, '2023-10-11 11:33:05', NULL),
(832, 1, 2, '2023-10-11 17:23:00', '2023-10-11', NULL, '2023-10-11 11:33:05', NULL),
(833, 1, 2, '2023-10-11 17:26:19', '2023-10-11', NULL, '2023-10-11 11:33:05', NULL),
(834, 1, 1, '2023-10-11 17:26:44', '2023-10-11', NULL, '2023-10-11 11:33:05', NULL),
(835, 1, 1, '2023-10-11 17:27:25', '2023-10-11', NULL, '2023-10-11 11:33:05', NULL),
(836, 1, 1, '2023-10-11 17:29:15', '2023-10-11', NULL, '2023-10-11 11:33:05', NULL),
(837, 1, 1, '2023-10-11 17:29:23', '2023-10-11', NULL, '2023-10-11 11:33:05', NULL),
(890, 1, 1, '2023-10-11 17:33:09', '2023-10-11', NULL, '2023-10-11 11:33:14', NULL),
(944, 1, 1, '2023-10-11 17:34:29', '2023-10-11', NULL, '2023-10-11 11:34:35', NULL),
(999, 1, 1, '2023-10-11 17:34:39', '2023-10-11', NULL, '2023-10-11 11:34:44', NULL),
(1055, 1, 1, '2023-10-11 17:34:47', '2023-10-11', NULL, '2023-10-11 11:34:53', NULL),
(1112, 1, 1, '2023-10-11 17:34:54', '2023-10-11', NULL, '2023-10-11 11:34:59', NULL),
(1170, 1, 1, '2023-10-11 17:35:12', '2023-10-11', NULL, '2023-10-11 11:35:17', NULL),
(1229, 1, 1, '2023-10-11 17:35:14', '2023-10-11', NULL, '2023-10-11 11:35:21', NULL),
(1230, 1, 1, '2023-10-11 17:35:16', '2023-10-11', NULL, '2023-10-11 11:35:21', NULL),
(1291, 1, 1, '2023-10-11 17:35:18', '2023-10-11', NULL, '2023-10-11 11:35:24', NULL),
(1353, 1, 1, '2023-10-11 17:37:07', '2023-10-11', NULL, '2023-10-11 11:37:14', NULL),
(1416, 1, 1, '2023-10-11 17:37:41', '2023-10-11', NULL, '2023-10-11 11:37:47', NULL),
(1480, 1, 1, '2023-10-11 17:38:45', '2023-10-11', NULL, '2023-10-11 11:38:50', NULL),
(1545, 1, 1, '2023-10-11 17:38:53', '2023-10-11', NULL, '2023-10-11 11:38:59', NULL),
(1611, 1, 1, '2023-10-16 13:49:13', '2023-10-16', NULL, '2023-10-16 07:58:07', NULL),
(1612, 1, 1, '2023-10-16 13:49:28', '2023-10-16', NULL, '2023-10-16 07:58:07', NULL),
(1647, 0, 1, '2024-02-27 14:48:00', '2024-02-27', 'Demo', '2024-02-27 02:52:28', '2024-02-27 02:52:28'),
(1648, 0, 5, '2024-02-27 14:48:00', '2024-02-27', 'Demo', '2024-02-27 02:52:28', '2024-02-27 02:52:28'),
(1649, 0, 3, '2024-02-27 14:48:00', '2024-02-27', 'Demo', '2024-02-27 02:52:28', '2024-02-27 02:52:28'),
(1675, 0, 1, '2024-02-27 10:00:00', '2024-02-27', 'Demo', '2024-02-27 05:01:45', '2024-02-27 05:01:45'),
(1676, 0, 5, '2024-02-27 10:00:00', '2024-02-27', 'Demo', '2024-02-27 05:01:45', '2024-02-27 05:01:45'),
(1677, 0, 3, '2024-02-27 10:00:00', '2024-02-27', 'Demo', '2024-02-27 05:01:45', '2024-02-27 05:01:45'),
(1678, 0, 6, '2024-02-27 10:00:00', '2024-02-27', 'Demo', '2024-02-27 05:01:46', '2024-02-27 05:01:46'),
(1679, 0, 1, '2024-02-27 09:00:00', '2024-02-27', 'Demo', '2024-02-27 05:16:28', '2024-02-27 05:16:28'),
(1680, 0, 1, '2024-02-27 17:16:00', '2024-02-27', 'Demo', '2024-02-27 05:16:28', '2024-02-27 05:16:28'),
(1681, 0, 5, '2024-02-27 09:00:00', '2024-02-27', 'Demo', '2024-02-27 05:16:29', '2024-02-27 05:16:29'),
(1682, 0, 5, '2024-02-27 17:16:00', '2024-02-27', 'Demo', '2024-02-27 05:16:29', '2024-02-27 05:16:29'),
(1683, 0, 3, '2024-02-27 09:00:00', '2024-02-27', 'Demo', '2024-02-27 05:16:29', '2024-02-27 05:16:29'),
(1684, 0, 3, '2024-02-27 17:16:00', '2024-02-27', 'Demo', '2024-02-27 05:16:29', '2024-02-27 05:16:29'),
(1685, 0, 6, '2024-02-27 09:00:00', '2024-02-27', 'Demo', '2024-02-27 05:16:29', '2024-02-27 05:16:29'),
(1686, 0, 6, '2024-02-27 17:16:00', '2024-02-27', 'Demo', '2024-02-27 05:16:29', '2024-02-27 05:16:29'),
(1687, 0, 1, '2024-02-27 16:16:00', '2024-02-27', 'Demo', '2024-02-27 05:16:55', '2024-02-27 05:16:55'),
(1688, 0, 5, '2024-02-27 16:16:00', '2024-02-27', 'Demo', '2024-02-27 05:16:55', '2024-02-27 05:16:55'),
(1689, 0, 3, '2024-02-27 16:16:00', '2024-02-27', 'Demo', '2024-02-27 05:16:55', '2024-02-27 05:16:55'),
(1690, 0, 6, '2024-02-27 16:16:00', '2024-02-27', 'Demo', '2024-02-27 05:16:55', '2024-02-27 05:16:55'),
(1691, 0, 1, '2024-03-05 08:54:00', '2024-03-05', 'Demo', '2024-03-04 23:54:28', '2024-03-04 23:54:28'),
(1692, 0, 1, '2024-03-05 12:40:00', '2024-03-05', 'Demo', '2024-03-06 00:41:03', '2024-03-06 00:41:03'),
(1693, 0, 1, '2024-03-05 12:43:00', '2024-03-05', 'Demo', '2024-03-06 00:44:11', '2024-03-06 00:44:11'),
(1694, 0, 1, '2024-03-06 09:30:00', '2024-03-06', 'Demo', '2024-03-06 03:30:16', '2024-03-06 03:30:16'),
(1695, 0, 1, '2024-03-06 15:30:00', '2024-03-06', 'Demo', '2024-03-06 03:30:16', '2024-03-06 03:30:16'),
(1700, 0, 6, '2024-03-06 09:30:00', '2024-03-06', 'Demo', '2024-03-06 03:30:16', '2024-03-06 03:30:16'),
(1701, 0, 6, '2024-03-06 15:30:00', '2024-03-06', 'Demo', '2024-03-06 03:30:16', '2024-03-06 03:30:16'),
(1702, 0, 1, '2024-03-20 09:30:00', '2024-03-20', 'Demo', '2024-03-21 00:23:36', '2024-03-21 00:23:36'),
(1703, 0, 1, '2024-03-21 18:23:00', '2024-03-21', 'Demo', '2024-03-21 00:23:36', '2024-03-21 00:23:36'),
(1704, 0, 5, '2024-03-20 09:30:00', '2024-03-20', 'Demo', '2024-03-21 00:23:36', '2024-03-21 00:23:36'),
(1705, 0, 5, '2024-03-21 18:23:00', '2024-03-21', 'Demo', '2024-03-21 00:23:36', '2024-03-21 00:23:36'),
(1706, 0, 3, '2024-03-20 09:30:00', '2024-03-20', 'Demo', '2024-03-21 00:23:36', '2024-03-21 00:23:36'),
(1707, 0, 3, '2024-03-21 18:23:00', '2024-03-21', 'Demo', '2024-03-21 00:23:36', '2024-03-21 00:23:36'),
(1708, 0, 6, '2024-03-20 09:30:00', '2024-03-20', 'Demo', '2024-03-21 00:23:36', '2024-03-21 00:23:36'),
(1709, 0, 6, '2024-03-21 18:23:00', '2024-03-21', 'Demo', '2024-03-21 00:23:36', '2024-03-21 00:23:36'),
(1710, 0, 1, '2024-03-19 10:30:00', '2024-03-19', 'Demo', '2024-03-21 00:24:00', '2024-03-21 00:24:00'),
(1711, 0, 1, '2024-03-21 18:23:00', '2024-03-21', 'Demo', '2024-03-21 00:24:00', '2024-03-21 00:24:00'),
(1712, 0, 5, '2024-03-19 10:30:00', '2024-03-19', 'Demo', '2024-03-21 00:24:00', '2024-03-21 00:24:00'),
(1713, 0, 5, '2024-03-21 18:23:00', '2024-03-21', 'Demo', '2024-03-21 00:24:00', '2024-03-21 00:24:00'),
(1714, 0, 3, '2024-03-19 10:30:00', '2024-03-19', 'Demo', '2024-03-21 00:24:00', '2024-03-21 00:24:00'),
(1715, 0, 3, '2024-03-21 18:23:00', '2024-03-21', 'Demo', '2024-03-21 00:24:00', '2024-03-21 00:24:00'),
(1716, 0, 6, '2024-03-19 10:30:00', '2024-03-19', 'Demo', '2024-03-21 00:24:00', '2024-03-21 00:24:00'),
(1717, 0, 6, '2024-03-21 18:23:00', '2024-03-21', 'Demo', '2024-03-21 00:24:00', '2024-03-21 00:24:00'),
(1718, 0, 1, '2024-03-21 10:15:00', '2024-03-21', 'Demo', '2024-03-21 00:26:16', '2024-03-21 00:26:16'),
(1719, 0, 5, '2024-03-21 10:15:00', '2024-03-21', 'Demo', '2024-03-21 00:26:16', '2024-03-21 00:26:16'),
(1720, 0, 3, '2024-03-21 10:15:00', '2024-03-21', 'Demo', '2024-03-21 00:26:16', '2024-03-21 00:26:16'),
(1721, 0, 6, '2024-03-21 10:15:00', '2024-03-21', 'Demo', '2024-03-21 00:26:16', '2024-03-21 00:26:16'),
(1722, 0, 1, '2024-03-24 08:53:00', '2024-03-24', 'Demo', '2024-03-24 00:53:48', '2024-03-24 00:53:48'),
(1723, 0, 2, '2024-03-24 08:53:00', '2024-03-24', 'Demo', '2024-03-24 00:53:48', '2024-03-24 00:53:48');

-- --------------------------------------------------------

--
-- Table structure for table `break_times`
--

CREATE TABLE `break_times` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `start_time` time DEFAULT NULL,
  `end_time` time DEFAULT NULL,
  `created_by` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `break_times`
--

INSERT INTO `break_times` (`id`, `start_time`, `end_time`, `created_by`, `created_at`, `updated_at`) VALUES
(1, '13:00:00', '14:00:00', 'Demo', '2024-01-11 00:27:03', '2024-01-11 00:27:03');

-- --------------------------------------------------------

--
-- Table structure for table `commissions`
--

CREATE TABLE `commissions` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `employee_id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `amount` double(20,2) NOT NULL DEFAULT 0.00,
  `percentage` decimal(5,2) DEFAULT 0.00,
  `type` tinyint(4) DEFAULT 1,
  `created_by` int(11) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;

--
-- Dumping data for table `commissions`
--

INSERT INTO `commissions` (`id`, `employee_id`, `title`, `amount`, `percentage`, `type`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 1, 'Commission Title', 3000.00, 5.00, 2, 1, '2023-07-13 08:57:29', '2023-07-19 11:49:28'),
(2, 1, 'Commission Title', 5000.00, 0.00, 1, 1, '2023-07-19 11:36:53', '2023-07-19 11:46:10');

-- --------------------------------------------------------

--
-- Table structure for table `company_settings`
--

CREATE TABLE `company_settings` (
  `id` int(10) UNSIGNED NOT NULL,
  `company_name` varchar(255) NOT NULL,
  `company_details` varchar(255) DEFAULT NULL,
  `proprietor_name` varchar(255) DEFAULT NULL,
  `company_address` varchar(255) DEFAULT NULL,
  `factory_address` text DEFAULT NULL,
  `company_mobile` varchar(255) DEFAULT NULL,
  `company_phone` varchar(255) DEFAULT NULL,
  `company_email` varchar(255) DEFAULT NULL,
  `website_url` varchar(255) DEFAULT NULL,
  `fb_url` varchar(255) DEFAULT NULL,
  `twitter_url` varchar(255) DEFAULT NULL,
  `linkdin_url` varchar(255) DEFAULT NULL,
  `instagram_url` varchar(255) DEFAULT NULL,
  `trade_license` varchar(100) DEFAULT NULL,
  `tin_no` varchar(100) DEFAULT NULL,
  `bin_no` varchar(100) DEFAULT NULL,
  `vat_no` varchar(100) DEFAULT NULL,
  `vat_rate` int(11) DEFAULT NULL,
  `currency` varchar(100) DEFAULT NULL,
  `water_mark` varchar(255) DEFAULT NULL,
  `company_logo_one` varchar(255) DEFAULT NULL,
  `company_logo_two` varchar(255) DEFAULT NULL,
  `company_footer_logo` varchar(255) DEFAULT NULL,
  `status` int(11) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `company_settings`
--

INSERT INTO `company_settings` (`id`, `company_name`, `company_details`, `proprietor_name`, `company_address`, `factory_address`, `company_mobile`, `company_phone`, `company_email`, `website_url`, `fb_url`, `twitter_url`, `linkdin_url`, `instagram_url`, `trade_license`, `tin_no`, `bin_no`, `vat_no`, `vat_rate`, `currency`, `water_mark`, `company_logo_one`, `company_logo_two`, `company_footer_logo`, `status`, `created_at`, `updated_at`) VALUES
(5, 'JAGO CORPORATION PLC.', 'Manufacturing Company', NULL, 'Head Office: 51, Central Road, Dhanmondi, Dhaka-1205', 'Factory Address: Jatramura, Tarabo, Rupganj, Narayanganj', '+8801896-047230', '+88-02-58610056-58610059', 'info@jagocorporationplc.com', 'https://www.jagocorporationplc.com', NULL, NULL, NULL, NULL, '---', '---', '---', NULL, NULL, 'BDT', NULL, 'public/images/company/28-11-2024-17-23-22_jago-corporation-plc-logo.png', 'public/images/company/28-11-2024-17-23-22_jago-corporation-plc-small-logo.jpg', 'public/images/company/11-08-2024-12-36-19-logo.png', 1, '2024-08-11 06:36:19', '2024-11-28 22:23:22');

-- --------------------------------------------------------

--
-- Table structure for table `customers`
--

CREATE TABLE `customers` (
  `id` int(10) UNSIGNED NOT NULL,
  `customer_type` int(11) DEFAULT NULL,
  `ac_id` int(10) DEFAULT NULL,
  `customer_code` varchar(150) DEFAULT NULL,
  `customer_name` varchar(150) DEFAULT NULL,
  `customer_gender` int(11) DEFAULT 0,
  `customer_DOB` date DEFAULT NULL,
  `customer_mobile` varchar(100) DEFAULT NULL,
  `customer_email` varchar(50) DEFAULT NULL,
  `image` varchar(255) DEFAULT NULL,
  `nid_number` varchar(100) DEFAULT NULL,
  `vat_reg_no` varchar(100) DEFAULT NULL,
  `tin_no` varchar(100) DEFAULT NULL,
  `trade_license` varchar(100) DEFAULT NULL,
  `discount_rate` decimal(18,2) DEFAULT 0.00,
  `security_deposit` decimal(18,2) DEFAULT 0.00,
  `credit_limit` decimal(18,2) DEFAULT 0.00,
  `customer_area` varchar(150) DEFAULT NULL,
  `customer_address` longtext DEFAULT NULL,
  `shipping_address` longtext DEFAULT NULL,
  `shipping_contact` varchar(100) DEFAULT NULL,
  `status` int(11) DEFAULT 0,
  `done_by` varchar(100) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `customers`
--

INSERT INTO `customers` (`id`, `customer_type`, `ac_id`, `customer_code`, `customer_name`, `customer_gender`, `customer_DOB`, `customer_mobile`, `customer_email`, `image`, `nid_number`, `vat_reg_no`, `tin_no`, `trade_license`, `discount_rate`, `security_deposit`, `credit_limit`, `customer_area`, `customer_address`, `shipping_address`, `shipping_contact`, `status`, `done_by`, `created_at`, `updated_at`) VALUES
(1, 1, 108, '01', 'Customer 1', 0, NULL, '01681952638', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Dhaka, Bangladesh', NULL, NULL, 1, 'Demo', '2024-09-11 12:48:20', '2024-09-24 17:15:43'),
(2, 1, 110, '02', 'Customer 2', 0, NULL, '0152264596', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Dhaka, Bangladesh', NULL, NULL, 1, 'Admin', '2024-09-12 05:29:07', '2024-09-24 17:16:10'),
(3, 1, 111, '03', 'MRS Sabrina', 0, NULL, '01789869140', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'mirpur, dhaka', NULL, NULL, 0, 'Admin', '2024-09-17 22:12:29', '2024-10-01 14:34:06'),
(4, 1, 113, '001', 'Dr. Sabrina Rahman', 0, NULL, '01733722480', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'kazipara, mirpur Dhaka', NULL, NULL, 1, 'Admin', '2024-09-24 17:15:01', '2024-09-24 17:15:56'),
(5, 1, 114, '002', 'Md. Ashraf', NULL, NULL, '0171-8807815', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'mirpur, dhaka', NULL, NULL, 1, 'Admin', '2024-09-26 23:21:53', '2024-10-30 18:15:54'),
(6, 1, 115, '003', 'Mr Sabbir', NULL, NULL, '0162009339', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '51/A North Road.', NULL, NULL, 1, 'Admin', '2024-09-27 00:12:00', '2024-09-27 00:12:00'),
(7, 1, 116, '004', 'Jihad Juice and fast Food.', NULL, NULL, '01815429270', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '63 B Green Road( K M Fojiullah Road)', NULL, NULL, 1, 'Admin', '2024-09-27 00:14:13', '2024-09-27 00:14:13'),
(8, 1, 117, '005', 'Mr Rupon', NULL, NULL, '01619056367', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Novana Tower.', NULL, NULL, 1, 'Admin', '2024-09-27 00:17:06', '2024-09-27 00:17:06'),
(9, 1, 118, '006', 'Mr Monir Hossain.', NULL, NULL, '01911421255', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Plot-12,Road,6,2ndFloor,Senpura Mirpur-10.', NULL, NULL, 1, 'Admin', '2024-09-27 00:19:38', '2024-09-27 00:19:38'),
(10, 1, 119, '007', 'Mr Raju', NULL, NULL, '01705018687', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Banani,Dhaka.', NULL, NULL, 1, 'Admin', '2024-09-27 00:20:31', '2024-09-27 00:20:31'),
(11, 1, 120, '008', 'Md Tanvir.', NULL, NULL, '01684771151', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Uttora', NULL, NULL, 1, 'Admin', '2024-09-27 00:21:21', '2024-09-27 00:21:21'),
(12, 1, 121, '009', 'Mr Feroz Alam', NULL, NULL, '01715253166', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Saddam Paper House', NULL, NULL, 1, 'Admin', '2024-09-27 00:22:20', '2024-09-27 00:22:20'),
(13, 1, 122, '010', 'Jafor Raja', NULL, NULL, '01711334612', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'H-295,R-19/B,Mahakhali.', NULL, NULL, 1, 'Admin', '2024-09-27 00:23:41', '2024-09-27 00:23:41'),
(14, 1, 123, '011', 'Md Alamgir', NULL, NULL, '01678012177', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Mirpur-10,Dhaka.', NULL, NULL, 1, 'Admin', '2024-09-27 00:35:43', '2024-09-27 00:35:43'),
(15, 1, 124, '012', 'Nur Al Mahedi.', NULL, NULL, '01709452377', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Mirpur,Dhaka.', NULL, NULL, 1, 'Admin', '2024-09-27 00:41:06', '2024-09-27 00:41:06'),
(16, 1, 125, '013', 'Md Saiful islam.', NULL, NULL, '01787107774', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Jattrabari', NULL, NULL, 1, 'Admin', '2024-09-27 00:43:15', '2024-09-27 00:43:15'),
(17, 1, 126, '014', 'Mr Habibur', NULL, NULL, '01721797806', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Kollyanpur', NULL, NULL, 1, 'Admin', '2024-09-27 00:46:25', '2024-09-27 00:46:25'),
(18, 1, 127, '015', 'Mr Tanvir (  Rubel Acc)', NULL, NULL, '01723619177', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Mirpur-1', NULL, NULL, 1, 'Admin', '2024-09-27 00:47:24', '2024-09-27 00:47:24'),
(19, 1, 128, '016', 'Md Ziaul Haque(Zia Sir)', 0, NULL, '01751526984', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Shobhanbug govt stuff Quater', NULL, NULL, 1, 'Admin', '2024-09-27 00:49:06', '2024-09-28 20:26:58'),
(20, 1, 129, '017', 'Shahanaz Bristy', 0, NULL, '01724928335', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Mirpur 12 ,Dhaka.', NULL, NULL, 1, 'Admin', '2024-09-27 00:50:26', '2024-09-28 16:27:35'),
(21, 1, 130, '020', 'Mr Emon', 1, NULL, '01678012173', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Malibag,Dhaka.', NULL, NULL, 1, 'Admin', '2024-09-27 00:52:06', '2024-09-28 16:26:59'),
(22, 1, 131, '023', 'Joy', 1, NULL, '01754242658', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Dhammondi,8A.', NULL, NULL, 1, 'Admin', '2024-09-27 00:54:51', '2024-09-28 16:26:50'),
(23, 1, 132, '025', 'Mr Soriful Islam', 1, NULL, '01711299071', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Mirpur', NULL, NULL, 1, 'Admin', '2024-09-27 00:55:58', '2024-09-28 19:28:41'),
(24, 1, 133, '029', 'Sohel (Zia sir)', 1, NULL, '01754577743', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Pirerbug, Mirpur -2.', NULL, NULL, 1, 'Admin', '2024-09-28 16:29:37', '2024-09-28 16:29:37'),
(25, 1, 134, '043', 'Mrs. Pinky.', 0, NULL, '01684568800', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Shekhentek,RD-3.', NULL, NULL, 1, 'Admin', '2024-09-28 16:33:23', '2024-09-28 16:33:23'),
(26, 1, 135, '026', 'Md Hossain Ahmed', 1, NULL, '01780448844', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Shankar,Dhanmondi, Dhaka.', NULL, NULL, 1, 'Admin', '2024-09-28 16:41:45', '2024-09-28 16:41:45'),
(27, 1, 136, '027', 'Ms Najnin.', 0, NULL, '01960405618', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '19/4 Uttar Tolarbug.', NULL, NULL, 1, 'Admin', '2024-09-28 16:43:54', '2024-09-28 16:43:54'),
(28, 1, 137, '035', 'Shakwat Rahim  Khan.', 1, NULL, '01716-411860', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Dhanmondi 15.', NULL, NULL, 1, 'Admin', '2024-09-28 16:46:37', '2024-09-28 16:46:37'),
(29, 1, 138, '036', 'Mr Robiul.', 1, NULL, '01754-858644', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Sobujbag,Dhaka.', NULL, NULL, 1, 'Admin', '2024-09-28 16:49:43', '2024-09-28 17:42:51'),
(30, 1, 139, '038', 'Abir', 1, NULL, '01723-619177.', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Mugdapara,Dhaka.', NULL, NULL, 1, 'Admin', '2024-09-28 16:51:07', '2024-09-28 16:51:07'),
(31, 1, 140, '039', 'Mr Adnan', 1, NULL, '01732-525888', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Ibrahimpur.', NULL, NULL, 1, 'Admin', '2024-09-28 16:53:52', '2024-09-28 16:53:52'),
(32, 1, 141, '041', 'Mr Ashraful.', 1, NULL, '01980301353', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Rupnagor,Eslarp Aousing, Mirpur 12.', NULL, NULL, 1, 'Admin', '2024-09-28 16:56:58', '2024-09-28 16:56:58'),
(33, 1, 142, '021', 'Sonali Paper and Board Mills.', 1, NULL, '01896047230', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Dhanmondi, Central Road.', NULL, NULL, 1, 'Admin', '2024-09-28 18:59:58', '2024-09-28 18:59:58'),
(34, 1, 143, '030', 'Md Alomgir Sir.', 1, NULL, '016788012177', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Mirpur 10.', NULL, NULL, 1, 'Admin', '2024-09-28 20:24:05', '2024-09-28 20:24:05'),
(35, 1, 144, '032.', 'Mr Monu.', 1, NULL, '01911424255', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Mirpur-13.', NULL, NULL, 1, 'Admin', '2024-09-28 21:14:25', '2024-09-28 21:14:25'),
(36, 1, 145, '044', 'Sonali Paper  Mill Head Office Centeen.', NULL, NULL, '01896047230', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Dhanmondi Central road.', NULL, NULL, 1, 'Admin', '2024-09-28 21:39:41', '2024-09-28 21:39:41'),
(37, 1, 146, '045', 'Istiaque Ahmed', 1, NULL, '01715070700', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Bangalmotor', NULL, NULL, 1, 'Admin', '2024-09-28 21:45:50', '2024-09-28 21:45:50'),
(38, 1, 147, '046', 'Md Lokman Hossain.', NULL, NULL, '01678020868', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Tarabo Rupgong , Narayangang.', NULL, NULL, 1, 'Admin', '2024-09-28 21:47:18', '2024-09-28 21:47:18'),
(39, 1, 148, '050', 'Md Monir.', 1, NULL, '01624-356814', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Mirpur-10,Road 6,P-12.', NULL, NULL, 0, 'Admin', '2024-09-28 22:17:43', '2024-09-29 17:33:38'),
(40, 1, 149, '051', 'Md Somrath.', 1, NULL, '01324356987', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Mirpur-1, F Block.', NULL, NULL, 1, 'Admin', '2024-09-28 22:19:14', '2024-09-28 22:19:14'),
(41, 1, 150, '064.', 'Dr. Tahseen Ali.', 1, NULL, '01762-806646', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'House-06, Park Road, Baridhara D. Zone.', NULL, NULL, 1, 'Admin', '2024-10-01 14:19:52', '2024-10-01 14:19:52'),
(42, 1, 151, '066', 'Md.Liton', NULL, NULL, '01737515273', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Boro Kusherbag,Jinjira keranigong.', NULL, NULL, 1, 'Admin', '2024-10-06 23:37:30', '2024-10-06 23:37:30'),
(43, 1, 152, '067', 'Khorshed', NULL, NULL, '01732-988324.', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Noya Bajar, Jindabahar,Police Fari Goli.', NULL, NULL, 1, 'Admin', '2024-10-06 23:40:02', '2024-10-06 23:40:02'),
(44, 1, 153, '065', 'AKM Haruner Rashid', NULL, NULL, '01711105322', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Swami bag behind Mitali School.', NULL, NULL, 1, 'Admin', '2024-10-16 23:18:43', '2024-10-30 18:09:06'),
(45, 1, 154, '073', 'Mr. Shimul', NULL, NULL, '01735666301', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Shewrapara,Ibrahimpur,Kamal khan Road.', NULL, NULL, 1, 'Admin', '2024-10-19 22:37:05', '2024-10-30 17:20:24'),
(46, 1, 158, '074', 'Exim Bank', NULL, NULL, '01611-954442', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Noyerhat, Savar.', NULL, NULL, 1, 'Admin', '2024-10-30 17:48:33', '2024-10-30 17:48:33'),
(47, 1, 159, NULL, 'Mrs. Nazma', NULL, NULL, '01309312356', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Mirpur 2, Pirerbag', NULL, NULL, 1, 'Admin', '2024-11-19 22:13:59', '2024-11-19 22:13:59'),
(48, 1, 160, NULL, 'Muza Wasin', NULL, NULL, '0171129410', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Baily Road, Viqarunnisa', NULL, NULL, 1, 'Admin', '2024-11-19 22:22:46', '2024-11-19 22:22:46'),
(49, 1, 161, NULL, 'BD Unani & Ayurbedic', NULL, NULL, '01712-564542', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Indira Road, Farmgate', NULL, NULL, 1, 'Admin', '2024-11-19 22:28:13', '2024-11-19 22:28:13'),
(50, 1, 162, NULL, 'MD Jahid Hasan', NULL, NULL, '01755-565656', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Noyabazar', NULL, NULL, 1, 'Admin', '2024-11-19 22:35:26', '2024-11-19 22:35:26'),
(51, 1, 163, NULL, 'MD Soleman', NULL, NULL, '01705-736088', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Dhanmondi 1', NULL, NULL, 1, 'Admin', '2024-11-19 22:49:19', '2024-11-19 22:49:19'),
(52, 1, 164, NULL, 'MD Rakib Ali', NULL, NULL, '01777-777777', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Kodomtoli', NULL, NULL, 1, 'Admin', '2024-11-19 22:52:38', '2024-11-19 22:52:38'),
(53, 1, 165, NULL, 'Mr Habib', NULL, NULL, '01777-777777', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Dhanmondi- 06', NULL, NULL, 1, 'Admin', '2024-11-19 22:56:25', '2024-11-19 22:56:25'),
(54, 1, 166, NULL, 'Shadat Hasan', NULL, NULL, '01833-673299', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 'Admin', '2024-11-19 23:05:22', '2024-11-19 23:05:22'),
(55, 1, 167, NULL, 'MD limon', NULL, NULL, '01711-299071', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 'Admin', '2024-11-23 22:30:48', '2024-11-23 22:30:48'),
(56, 1, 168, NULL, 'Md Junayed Hossain', NULL, NULL, '01761-193501', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '65 Elephant Road', NULL, NULL, 1, 'Admin', '2024-11-26 22:14:41', '2024-11-26 22:14:41');

-- --------------------------------------------------------

--
-- Table structure for table `customer_ledgers`
--

CREATE TABLE `customer_ledgers` (
  `id` int(10) UNSIGNED NOT NULL,
  `ledger_date` date NOT NULL,
  `customer_id` int(10) UNSIGNED DEFAULT NULL,
  `invoice_no` varchar(50) DEFAULT NULL,
  `debit` decimal(18,2) NOT NULL DEFAULT 0.00,
  `credit` decimal(18,2) NOT NULL DEFAULT 0.00,
  `payment_type` varchar(50) DEFAULT NULL,
  `bank_name` varchar(50) DEFAULT NULL,
  `cheque_no` varchar(50) DEFAULT NULL,
  `cheque_date` date DEFAULT NULL,
  `card_no` varchar(50) DEFAULT NULL,
  `bkash_merchant_number` varchar(50) DEFAULT NULL,
  `bkash_payment_number` varchar(50) DEFAULT NULL,
  `bkash_trx_id` varchar(50) DEFAULT NULL,
  `remarks` longtext DEFAULT NULL,
  `is_previous_due` tinyint(4) NOT NULL DEFAULT 0,
  `status` int(11) NOT NULL DEFAULT 1,
  `done_by` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `customer_ledgers`
--

INSERT INTO `customer_ledgers` (`id`, `ledger_date`, `customer_id`, `invoice_no`, `debit`, `credit`, `payment_type`, `bank_name`, `cheque_no`, `cheque_date`, `card_no`, `bkash_merchant_number`, `bkash_payment_number`, `bkash_trx_id`, `remarks`, `is_previous_due`, `status`, `done_by`, `created_at`, `updated_at`) VALUES
(1, '2024-09-11', 1, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Demo', '2024-09-11 12:48:20', '2024-09-11 12:48:20'),
(2, '2024-09-12', 2, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-09-12 05:29:07', '2024-09-12 05:29:07'),
(3, '2024-09-17', 3, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-09-17 22:12:29', '2024-09-17 22:12:29'),
(4, '2024-09-24', 4, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-09-24 17:15:01', '2024-09-24 17:15:01'),
(5, '2024-09-26', 5, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-09-26 23:21:53', '2024-09-26 23:21:53'),
(6, '2024-09-26', 6, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-09-27 00:12:00', '2024-09-27 00:12:00'),
(7, '2024-09-26', 7, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-09-27 00:14:13', '2024-09-27 00:14:13'),
(8, '2024-09-26', 8, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-09-27 00:17:06', '2024-09-27 00:17:06'),
(9, '2024-09-26', 9, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-09-27 00:19:38', '2024-09-27 00:19:38'),
(10, '2024-09-26', 10, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-09-27 00:20:31', '2024-09-27 00:20:31'),
(11, '2024-09-26', 11, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-09-27 00:21:21', '2024-09-27 00:21:21'),
(12, '2024-09-26', 12, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-09-27 00:22:20', '2024-09-27 00:22:20'),
(13, '2024-09-26', 13, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-09-27 00:23:41', '2024-09-27 00:23:41'),
(14, '2024-09-26', 14, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-09-27 00:35:43', '2024-09-27 00:35:43'),
(15, '2024-09-26', 15, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-09-27 00:41:06', '2024-09-27 00:41:06'),
(16, '2024-09-26', 16, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-09-27 00:43:15', '2024-09-27 00:43:15'),
(17, '2024-09-26', 17, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-09-27 00:46:25', '2024-09-27 00:46:25'),
(18, '2024-09-26', 18, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-09-27 00:47:24', '2024-09-27 00:47:24'),
(19, '2024-09-26', 19, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-09-27 00:49:06', '2024-09-27 00:49:06'),
(20, '2024-09-26', 20, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-09-27 00:50:26', '2024-09-27 00:50:26'),
(21, '2024-09-26', 21, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-09-27 00:52:06', '2024-09-27 00:52:06'),
(22, '2024-09-26', 22, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-09-27 00:54:51', '2024-09-27 00:54:51'),
(23, '2024-09-26', 23, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-09-27 00:55:58', '2024-09-27 00:55:58'),
(24, '2024-09-28', 24, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-09-28 16:29:37', '2024-09-28 16:29:37'),
(25, '2024-09-28', 25, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-09-28 16:33:23', '2024-09-28 16:33:23'),
(26, '2024-09-28', 26, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-09-28 16:41:45', '2024-09-28 16:41:45'),
(27, '2024-09-28', 27, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-09-28 16:43:54', '2024-09-28 16:43:54'),
(28, '2024-09-28', 28, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-09-28 16:46:37', '2024-09-28 16:46:37'),
(29, '2024-09-28', 29, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-09-28 16:49:43', '2024-09-28 16:49:43'),
(30, '2024-09-28', 30, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-09-28 16:51:07', '2024-09-28 16:51:07'),
(31, '2024-09-28', 31, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-09-28 16:53:52', '2024-09-28 16:53:52'),
(32, '2024-09-28', 32, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-09-28 16:56:58', '2024-09-28 16:56:58'),
(33, '2024-09-28', 33, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-09-28 18:59:58', '2024-09-28 18:59:58'),
(34, '2024-09-28', 34, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-09-28 20:24:05', '2024-09-28 20:24:05'),
(35, '2024-09-28', 35, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-09-28 21:14:25', '2024-09-28 21:14:25'),
(36, '2024-09-28', 36, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-09-28 21:39:41', '2024-09-28 21:39:41'),
(37, '2024-09-28', 37, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-09-28 21:45:50', '2024-09-28 21:45:50'),
(38, '2024-09-28', 38, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-09-28 21:47:18', '2024-09-28 21:47:18'),
(39, '2024-09-28', 39, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-09-28 22:17:43', '2024-09-28 22:17:43'),
(40, '2024-09-28', 40, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-09-28 22:19:14', '2024-09-28 22:19:14'),
(41, '2024-10-01', 41, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-10-01 14:19:52', '2024-10-01 14:19:52'),
(42, '2024-10-06', 42, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-10-06 23:37:30', '2024-10-06 23:37:30'),
(43, '2024-10-06', 43, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-10-06 23:40:02', '2024-10-06 23:40:02'),
(44, '2024-10-16', 44, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-10-16 23:18:43', '2024-10-16 23:18:43'),
(45, '2024-10-19', 45, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, 'Admin', '2024-10-19 22:37:05', '2024-10-19 22:37:05');

-- --------------------------------------------------------

--
-- Table structure for table `customer_types`
--

CREATE TABLE `customer_types` (
  `id` int(10) NOT NULL,
  `type_name` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `status` int(11) DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `customer_types`
--

INSERT INTO `customer_types` (`id`, `type_name`, `status`, `created_at`, `updated_at`) VALUES
(1, 'General Customer', 1, '2024-05-14 09:39:31', '2024-05-14 10:49:35'),
(2, 'Dealer', 1, '2024-05-14 09:40:39', '2024-05-14 09:42:14'),
(3, 'Retailer', 1, '2024-05-14 09:41:10', '2024-05-14 09:42:04'),
(4, 'Wholesaler', 1, '2024-05-14 09:41:57', '2024-05-14 09:41:57'),
(5, 'Regular', 1, '2024-05-23 08:04:34', '2024-05-23 08:04:34');

-- --------------------------------------------------------

--
-- Table structure for table `deductions`
--

CREATE TABLE `deductions` (
  `id` bigint(20) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `deduction_head` int(11) NOT NULL,
  `amount` double(20,2) NOT NULL DEFAULT 0.00,
  `percentage` decimal(5,2) DEFAULT 0.00,
  `type` tinyint(4) DEFAULT 1,
  `created_by` varchar(100) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `deduction_heads`
--

CREATE TABLE `deduction_heads` (
  `id` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` tinyint(4) DEFAULT 1,
  `created_by` int(11) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `deduction_heads`
--

INSERT INTO `deduction_heads` (`id`, `name`, `status`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 'TAX', 1, 1, '2023-07-13 07:21:21', '2023-12-17 05:14:33'),
(2, 'P/F', 1, 1, '2023-07-13 07:21:30', '2023-12-17 05:14:44'),
(0, 'Absent', 1, 1, '2023-12-17 04:55:26', '2023-12-17 05:16:54');

-- --------------------------------------------------------

--
-- Table structure for table `deduction_options`
--

CREATE TABLE `deduction_options` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `created_by` int(11) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;

-- --------------------------------------------------------

--
-- Table structure for table `employees`
--

CREATE TABLE `employees` (
  `id` int(11) NOT NULL,
  `user_id` bigint(20) DEFAULT NULL,
  `email` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `employee_code` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `employee_name` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `gender` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `dob` date DEFAULT NULL,
  `nid` int(20) DEFAULT NULL,
  `birth_id` int(20) DEFAULT NULL,
  `blood_group` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `marital_status` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `spouse_name` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `religion` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `mobile` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `mobile_two` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `emergency_contact_person` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `emergency_contact_number` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `father_name` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `mother_name` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `present_address` varchar(250) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `permanent_address` varchar(350) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `highest_education` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `job_status` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `quite_date` date DEFAULT NULL,
  `quite_type` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `photo` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `signature` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `order` int(11) DEFAULT 1,
  `status` int(11) DEFAULT 1,
  `salary_held_up` int(11) DEFAULT 0,
  `attendance_bonus` int(11) DEFAULT 0,
  `bus_using` int(10) DEFAULT 0,
  `provident_fund` int(10) DEFAULT 0,
  `income_tax` int(10) DEFAULT 0,
  `mobile_allowance` int(10) DEFAULT 0,
  `over_time` int(10) DEFAULT 0,
  `created_by` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `posting_date` date DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `employees`
--

INSERT INTO `employees` (`id`, `user_id`, `email`, `employee_code`, `employee_name`, `gender`, `dob`, `nid`, `birth_id`, `blood_group`, `marital_status`, `spouse_name`, `religion`, `mobile`, `mobile_two`, `emergency_contact_person`, `emergency_contact_number`, `father_name`, `mother_name`, `present_address`, `permanent_address`, `highest_education`, `job_status`, `quite_date`, `quite_type`, `photo`, `signature`, `order`, `status`, `salary_held_up`, `attendance_bonus`, `bus_using`, `provident_fund`, `income_tax`, `mobile_allowance`, `over_time`, `created_by`, `posting_date`, `created_at`, `updated_at`) VALUES
(38, NULL, NULL, '000001', 'Employee 1', 'Female', '2024-02-01', 654554, 5641541, 'A+', 'Married', 'Spouse', 'Islam', NULL, NULL, NULL, NULL, 'Father Name', 'Mother Name', 'Present Address', 'Permanent Address', 'Highest Education', 'Provisional', '2024-02-15', '2', 'public/images/employee/14-03-2024-06-57-23_demo-profile.jpg', 'public/images/employee/14-03-2024-06-57-23_signature.png', 1, 1, 0, 0, 0, 0, 0, 0, 0, 'Demo', '2024-02-01', '2024-02-14 01:39:40', '2024-05-30 06:13:39'),
(39, NULL, NULL, '000005', 'Employee 5', 'Male', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Permanent', NULL, NULL, 'public/images/employee/14-03-2024-06-58-02_demo-profile.jpg', 'public/images/employee/14-03-2024-06-58-02_signature.png', 1, 1, 0, 0, 0, 0, 0, 0, 0, 'Demo', '2024-02-01', '2024-02-14 01:49:34', '2024-03-14 00:58:02'),
(40, NULL, NULL, '000003', 'Employee 3', 'Female', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Permanent', NULL, NULL, 'public/images/employee/14-03-2024-06-58-18_demo-profile.jpg', 'public/images/employee/14-03-2024-06-58-18_signature.png', 1, 1, 0, 0, 0, 0, 0, 0, 0, 'Demo', '2024-02-01', '2024-02-14 03:19:34', '2024-03-25 00:06:59'),
(41, NULL, NULL, '000006', 'Employee 6', 'Male', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Permanent', NULL, NULL, 'public/images/employee/14-03-2024-06-58-34_demo-profile.jpg', 'public/images/employee/14-03-2024-06-58-34_signature.png', 1, 1, 0, 0, 0, 0, 0, 0, 0, 'Demo', '2024-02-01', '2024-02-14 03:23:48', '2024-03-14 00:58:34'),
(43, NULL, NULL, '000002', 'Employee 2', 'Male', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Permanent', NULL, NULL, NULL, NULL, 1, 1, 0, 0, 0, 0, 0, 0, 0, 'Demo', '2024-03-01', '2024-03-23 23:53:43', '2024-03-23 23:53:43'),
(44, NULL, NULL, '000007', 'Employee 7', 'Male', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Permanent', NULL, NULL, NULL, NULL, 1, 1, 1, 0, 0, 0, 0, 0, 0, 'Demo', '2024-03-01', '2024-03-24 00:08:44', '2024-04-17 02:44:34');

-- --------------------------------------------------------

--
-- Table structure for table `employees_backup`
--

CREATE TABLE `employees_backup` (
  `id` int(11) NOT NULL DEFAULT 0,
  `user_id` bigint(20) NOT NULL,
  `branch_id` int(11) DEFAULT NULL,
  `department_id` int(11) DEFAULT NULL,
  `designation_id` int(11) DEFAULT NULL,
  `employee_code` varchar(50) DEFAULT NULL,
  `employee_name` varchar(100) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `dob` date DEFAULT NULL,
  `gender` varchar(10) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `blood_group` varchar(10) DEFAULT NULL,
  `marital_status` varchar(20) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `religion` varchar(100) DEFAULT NULL,
  `nid` varchar(100) DEFAULT NULL,
  `mobile` varchar(100) DEFAULT NULL,
  `mobile_two` varchar(20) DEFAULT NULL,
  `emergency_contact_person` varchar(100) DEFAULT NULL,
  `emergency_contact_number` varchar(100) DEFAULT NULL,
  `father_name` varchar(100) DEFAULT NULL,
  `mother_name` varchar(100) DEFAULT NULL,
  `present_address` varchar(250) DEFAULT NULL,
  `permanent_address` varchar(350) DEFAULT NULL,
  `job_status` varchar(50) DEFAULT NULL,
  `joining_date` date DEFAULT NULL,
  `order` int(11) DEFAULT 1,
  `status` int(11) DEFAULT 1,
  `photo` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `signature` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `highest_education` varchar(100) DEFAULT NULL,
  `reference_one_name` varchar(300) DEFAULT NULL,
  `reference_one_phone` varchar(150) DEFAULT NULL,
  `reference_one_address` varchar(300) DEFAULT NULL,
  `reference_two_name` varchar(300) DEFAULT NULL,
  `reference_two_phone` varchar(150) DEFAULT NULL,
  `reference_two_address` varchar(300) DEFAULT NULL,
  `created_by` int(11) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `employees_backup`
--

INSERT INTO `employees_backup` (`id`, `user_id`, `branch_id`, `department_id`, `designation_id`, `employee_code`, `employee_name`, `email`, `dob`, `gender`, `blood_group`, `marital_status`, `religion`, `nid`, `mobile`, `mobile_two`, `emergency_contact_person`, `emergency_contact_number`, `father_name`, `mother_name`, `present_address`, `permanent_address`, `job_status`, `joining_date`, `order`, `status`, `photo`, `signature`, `highest_education`, `reference_one_name`, `reference_one_phone`, `reference_one_address`, `reference_two_name`, `reference_two_phone`, `reference_two_address`, `created_by`, `created_at`, `updated_at`) VALUES
(16, 45, 1, 1, 2, '2023002', 'Robiul', 'e@demo.com', '2023-01-04', 'Male', 'A+', 'Married', 'Islam', '6556654645456654', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Permanent', '2023-12-04', 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, '2023-12-04 05:08:06', '2023-12-04 05:08:06');

-- --------------------------------------------------------

--
-- Table structure for table `employees_update`
--

CREATE TABLE `employees_update` (
  `id` int(11) NOT NULL DEFAULT 0,
  `user_id` bigint(20) NOT NULL,
  `branch_id` int(11) DEFAULT NULL,
  `department_id` int(11) DEFAULT NULL,
  `designation_id` int(11) DEFAULT NULL,
  `employee_code` varchar(50) DEFAULT NULL,
  `employee_name` varchar(100) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `dob` date DEFAULT NULL,
  `gender` varchar(10) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `blood_group` varchar(10) DEFAULT NULL,
  `marital_status` varchar(20) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `religion` varchar(100) DEFAULT NULL,
  `nid` varchar(100) DEFAULT NULL,
  `mobile` varchar(100) DEFAULT NULL,
  `mobile_two` varchar(20) DEFAULT NULL,
  `emergency_contact_person` varchar(100) DEFAULT NULL,
  `emergency_contact_number` varchar(100) DEFAULT NULL,
  `father_name` varchar(100) DEFAULT NULL,
  `mother_name` varchar(100) DEFAULT NULL,
  `present_address` varchar(250) DEFAULT NULL,
  `permanent_address` varchar(350) DEFAULT NULL,
  `job_status` varchar(50) DEFAULT NULL,
  `joining_date` date DEFAULT NULL,
  `order` int(11) DEFAULT 1,
  `status` int(11) DEFAULT 1,
  `photo` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `signature` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `highest_education` varchar(100) DEFAULT NULL,
  `reference_one_name` varchar(300) DEFAULT NULL,
  `reference_one_phone` varchar(150) DEFAULT NULL,
  `reference_one_address` varchar(300) DEFAULT NULL,
  `reference_two_name` varchar(300) DEFAULT NULL,
  `reference_two_phone` varchar(150) DEFAULT NULL,
  `reference_two_address` varchar(300) DEFAULT NULL,
  `created_by` int(11) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `employees_update`
--

INSERT INTO `employees_update` (`id`, `user_id`, `branch_id`, `department_id`, `designation_id`, `employee_code`, `employee_name`, `email`, `dob`, `gender`, `blood_group`, `marital_status`, `religion`, `nid`, `mobile`, `mobile_two`, `emergency_contact_person`, `emergency_contact_number`, `father_name`, `mother_name`, `present_address`, `permanent_address`, `job_status`, `joining_date`, `order`, `status`, `photo`, `signature`, `highest_education`, `reference_one_name`, `reference_one_phone`, `reference_one_address`, `reference_two_name`, `reference_two_phone`, `reference_two_address`, `created_by`, `created_at`, `updated_at`) VALUES
(16, 45, 1, 1, 2, '2023002', 'Robiul', 'e@demo.com', '2023-01-04', 'Male', 'A+', 'Married', 'Islam', '6556654645456654', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Permanent', '2023-12-04', 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, '2023-12-04 05:08:06', '2023-12-04 05:08:06'),
(16, 45, 1, 1, 2, '2023002', 'Robiul', 'e@demo.com', '2023-01-04', 'Male', 'A+', 'Married', 'Islam', '6556654645456654', NULL, NULL, NULL, NULL, 'Father', NULL, NULL, NULL, 'Permanent', '2023-12-04', 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, '2023-12-04 05:08:06', '2023-12-04 06:00:08'),
(1, 29, 1, 1, 1, '2', 'Md. Masum', 'masum@gmail.com', NULL, 'Male', 'B+', 'Married', NULL, NULL, '01500000000', '01700000000', NULL, NULL, NULL, NULL, 'Dhaka', 'Dhaka', 'Permanent', '2023-06-01', 2, 1, 'public/images/products/11-10-2023-04-33-10_MGL.jpg', 'public/images/products/11-10-2023-04-33-10-shahjalalasset_logo.jpg', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, '2023-09-19 01:43:09', '2023-12-04 01:01:19'),
(3, 31, 2, 1, 1, '1001', 'Mr. Reza', 'reza@gmail.com', NULL, 'Male', 'B+', NULL, NULL, NULL, '01900000000', NULL, NULL, NULL, NULL, NULL, 'Dhaka', 'Dhaka', 'Permanent', '2023-01-01', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, '2023-09-19 22:52:40', '2023-12-04 01:20:01'),
(1, 29, 2, 1, 1, '2', 'Md. Masum', 'masum@gmail.com', NULL, 'Male', 'B+', 'Married', NULL, NULL, '01500000000', '01700000000', NULL, NULL, NULL, NULL, 'Dhaka', 'Dhaka', 'Permanent', '2023-06-01', 2, 1, 'public/images/products/11-10-2023-04-33-10_MGL.jpg', 'public/images/products/11-10-2023-04-33-10-shahjalalasset_logo.jpg', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, '2023-09-19 01:43:09', '2023-12-10 02:20:11'),
(1, 29, 2, 4, 1, '2', 'Md. Masum', 'masum@gmail.com', NULL, 'Male', 'B+', 'Married', NULL, NULL, '01500000000', '01700000000', NULL, NULL, NULL, NULL, 'Dhaka', 'Dhaka', 'Permanent', '2023-06-01', 2, 1, 'public/images/products/11-10-2023-04-33-10_MGL.jpg', 'public/images/products/11-10-2023-04-33-10-shahjalalasset_logo.jpg', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, '2023-09-19 01:43:09', '2023-12-24 00:39:32'),
(1, 29, 2, 4, 1, '2', 'Md. Masum', 'masumbdonly@gmail.com', NULL, 'Male', 'B+', 'Married', NULL, NULL, '01500000000', '01700000000', NULL, NULL, NULL, NULL, 'Dhaka', 'Dhaka', 'Permanent', '2023-06-01', 2, 1, 'public/images/products/11-10-2023-04-33-10_MGL.jpg', 'public/images/products/11-10-2023-04-33-10-shahjalalasset_logo.jpg', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, '2023-09-19 01:43:09', '2023-12-24 01:35:31'),
(3, 31, 1, 1, 1, '1001', 'Mr. Reza', 'reza@gmail.com', NULL, 'Male', 'B+', NULL, NULL, NULL, '01900000000', NULL, NULL, NULL, NULL, NULL, 'Dhaka', 'Dhaka', 'Permanent', '2023-01-01', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, '2023-09-19 22:52:40', '2023-12-18 04:24:03'),
(2, 30, 2, 5, 2, '3', 'Mr. Munir', 'munir@gmail.com', NULL, 'Male', 'AB+', NULL, NULL, NULL, '01600000000', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Permanent', '2023-01-01', 4, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, '2023-09-19 22:45:47', '2023-12-04 01:18:10'),
(1, 29, 2, 4, 1, '2', 'Md. Masum', 'masum.azon@gmail.com', NULL, 'Male', 'B+', 'Married', NULL, NULL, '01500000000', '01700000000', NULL, NULL, NULL, NULL, 'Dhaka', 'Dhaka', 'Permanent', '2023-06-01', 2, 1, 'public/images/products/11-10-2023-04-33-10_MGL.jpg', 'public/images/products/11-10-2023-04-33-10-shahjalalasset_logo.jpg', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, '2023-09-19 01:43:09', '2023-12-24 01:51:55');

-- --------------------------------------------------------

--
-- Table structure for table `employee_delayin_earlyouts`
--

CREATE TABLE `employee_delayin_earlyouts` (
  `id` int(11) NOT NULL,
  `employee_id` int(11) DEFAULT NULL,
  `date` date DEFAULT NULL,
  `status` varchar(100) DEFAULT NULL,
  `remarks` varchar(255) DEFAULT NULL,
  `delay_in_time` time DEFAULT NULL,
  `early_out_time` time DEFAULT NULL,
  `done_by` varchar(50) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `employee_delayin_earlyouts`
--

INSERT INTO `employee_delayin_earlyouts` (`id`, `employee_id`, `date`, `status`, `remarks`, `delay_in_time`, `early_out_time`, `done_by`, `created_at`, `updated_at`) VALUES
(1, 40, '2023-10-01', 'out_of_office', 'Remarks', NULL, NULL, 'NRB LTD.', '2023-10-31 04:15:26', '2023-10-31 04:15:26'),
(2, 41, '2023-10-05', 'out_of_office', 'Remarks', NULL, NULL, 'NRB LTD.', '2023-10-31 04:33:07', '2023-10-31 04:33:07'),
(15, 40, '2024-03-05', 'absences', 'Remarks', NULL, NULL, 'Demo', '2024-03-05 00:23:28', '2024-03-05 00:23:28'),
(16, 38, '2024-03-06', 'absences', 'Remarks', NULL, NULL, 'Demo', '2024-03-06 03:31:41', '2024-03-06 03:31:41'),
(17, 39, '2024-03-06', 'out_of_office', 'Done', NULL, NULL, 'Demo', '2024-03-06 03:53:30', '2024-03-06 03:53:30');

-- --------------------------------------------------------

--
-- Table structure for table `employee_education`
--

CREATE TABLE `employee_education` (
  `id` int(11) NOT NULL,
  `employee_id` int(11) DEFAULT NULL,
  `exam` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `institution` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `passingyear` date DEFAULT NULL,
  `result` varchar(10) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `employee_education`
--

INSERT INTO `employee_education` (`id`, `employee_id`, `exam`, `institution`, `passingyear`, `result`, `created_at`, `updated_at`) VALUES
(1, 1, 'BSC', 'BUET', '2020-07-01', '3', '2023-09-19 01:44:12', '2023-10-10 04:54:01'),
(2, 4, 'MSC', 'BUET', '2023-10-01', '4', '2023-10-10 03:24:15', '2023-10-10 04:54:36'),
(3, 4, 'BSC', 'BUET', '2023-10-01', '3.5', '2023-10-10 03:26:49', '2023-10-10 05:19:55'),
(4, 1, 'MSC', 'BUET', '2023-10-01', '3.5', '2023-10-10 04:53:38', '2023-10-10 04:53:46'),
(5, 14, 'tryrty', 'rtyrt', '2023-11-26', '545', '2023-11-26 04:27:59', '2023-11-26 04:27:59'),
(6, 3, 'BSC', 'BUET', '2018-12-31', '4', '2023-12-31 01:50:08', '2023-12-31 04:53:55'),
(7, 3, 'MSC', 'DU', '2023-12-01', '4', '2023-12-31 04:45:38', '2023-12-31 04:49:17'),
(8, 38, 'BSC', 'BUET', '2024-03-01', '4', '2024-03-19 00:25:32', '2024-03-19 00:25:32');

-- --------------------------------------------------------

--
-- Table structure for table `employee_job_histories`
--

CREATE TABLE `employee_job_histories` (
  `id` int(11) NOT NULL,
  `employee_id` int(11) DEFAULT NULL,
  `company_name` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `designation` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `employee_job_histories`
--

INSERT INTO `employee_job_histories` (`id`, `employee_id`, `company_name`, `designation`, `start_date`, `end_date`, `created_at`, `updated_at`) VALUES
(1, 1, 'NRB Ltd.', 'Programmer', '2022-09-01', NULL, '2023-09-19 01:45:19', '2023-10-10 04:52:51'),
(2, 3, 'NRB', 'Programmer', '2020-12-01', NULL, '2023-12-31 01:50:30', '2023-12-31 04:53:37'),
(3, 3, 'Company Name', 'Programmer', '2023-12-01', '2024-01-01', '2023-12-31 03:36:51', '2023-12-31 04:44:29'),
(4, 3, 'Arnab IT', 'Programmer', '2023-12-01', '2023-12-09', '2023-12-31 04:44:56', '2023-12-31 04:50:04');

-- --------------------------------------------------------

--
-- Table structure for table `employee_job_responsibilities`
--

CREATE TABLE `employee_job_responsibilities` (
  `id` int(11) NOT NULL,
  `employee_id` int(11) DEFAULT NULL,
  `job_responsibility` varchar(500) DEFAULT NULL,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `employee_job_responsibilities`
--

INSERT INTO `employee_job_responsibilities` (`id`, `employee_id`, `job_responsibility`, `start_date`, `end_date`, `created_at`, `updated_at`) VALUES
(1, 3, '2024 demo ....', '2023-12-01', NULL, '2023-12-31 03:45:47', '2023-12-31 04:55:18'),
(2, 3, 'Job Responsibility .....', NULL, NULL, '2023-12-31 04:15:35', '2023-12-31 04:55:18'),
(3, 1, '2024 ....', NULL, NULL, '2023-12-31 05:04:00', '2023-12-31 05:04:00'),
(4, 38, 'Responsibility', NULL, NULL, '2024-03-19 00:26:00', '2024-03-19 00:26:00');

-- --------------------------------------------------------

--
-- Table structure for table `employee_leave_entries`
--

CREATE TABLE `employee_leave_entries` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `leave_year` smallint(6) DEFAULT NULL,
  `leave_settings_id` int(11) UNSIGNED DEFAULT NULL,
  `branch_id` int(11) DEFAULT NULL,
  `section_id` int(11) DEFAULT NULL,
  `employee_id` int(11) DEFAULT NULL,
  `alternative_employee_id` int(11) DEFAULT NULL,
  `leave_application_date` varchar(10) DEFAULT NULL,
  `leave_start_date` varchar(10) DEFAULT NULL,
  `leave_end_date` varchar(10) DEFAULT NULL,
  `reporting_date` varchar(10) DEFAULT NULL,
  `late_of_leave_month` varchar(10) DEFAULT NULL,
  `leave_type` varchar(100) DEFAULT NULL,
  `total_days` int(4) DEFAULT 0,
  `no_of_late` int(4) DEFAULT 0,
  `department_status` tinyint(4) DEFAULT 0,
  `hr_status` tinyint(4) DEFAULT 0,
  `management_status` tinyint(4) DEFAULT 0,
  `final_status` tinyint(4) DEFAULT 0,
  `reason_for_leave` varchar(155) DEFAULT NULL,
  `remarks` varchar(155) DEFAULT NULL,
  `done_by` varchar(55) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `employee_leave_entries`
--

INSERT INTO `employee_leave_entries` (`id`, `leave_year`, `leave_settings_id`, `branch_id`, `section_id`, `employee_id`, `alternative_employee_id`, `leave_application_date`, `leave_start_date`, `leave_end_date`, `reporting_date`, `late_of_leave_month`, `leave_type`, `total_days`, `no_of_late`, `department_status`, `hr_status`, `management_status`, `final_status`, `reason_for_leave`, `remarks`, `done_by`, `created_at`, `updated_at`) VALUES
(4, 2024, 3, NULL, 3, 41, NULL, '2024-03-20', '2024-03-20', '2024-03-20', NULL, NULL, 'Casual', 1, 0, 1, 0, 0, 1, NULL, NULL, 'Demo', '2024-03-20 03:14:40', '2024-03-21 00:27:20'),
(5, 2024, 2, NULL, 3, 40, NULL, '2024-03-20', '2024-03-20', '2024-03-20', NULL, NULL, 'Casual', 1, 0, 0, 0, 0, 0, NULL, NULL, 'Demo', '2024-03-20 03:28:02', '2024-03-20 03:28:02'),
(6, 2024, 2, NULL, 3, 40, NULL, '2024-03-20', '2024-03-20', '2024-03-20', NULL, NULL, 'Sick', 1, 0, 1, 0, 0, 1, NULL, 'Done', 'Demo', '2024-03-20 03:28:33', '2024-03-20 23:04:02');

-- --------------------------------------------------------

--
-- Table structure for table `employee_leave_settings`
--

CREATE TABLE `employee_leave_settings` (
  `id` int(11) NOT NULL,
  `leave_year` smallint(6) DEFAULT NULL,
  `branch_id` tinyint(4) DEFAULT NULL,
  `section_id` int(11) DEFAULT NULL,
  `employee_id` int(11) DEFAULT NULL,
  `casual_leave` decimal(5,2) DEFAULT 0.00,
  `sick_leave` decimal(5,2) DEFAULT 0.00,
  `annual_leave` decimal(5,2) DEFAULT 0.00,
  `special_leave` decimal(5,2) DEFAULT 0.00,
  `total_leave` decimal(5,2) DEFAULT 0.00,
  `status` tinyint(4) DEFAULT 0,
  `remarks` varchar(255) DEFAULT NULL,
  `done_by` varchar(155) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `employee_leave_settings`
--

INSERT INTO `employee_leave_settings` (`id`, `leave_year`, `branch_id`, `section_id`, `employee_id`, `casual_leave`, `sick_leave`, `annual_leave`, `special_leave`, `total_leave`, `status`, `remarks`, `done_by`, `created_at`, `updated_at`) VALUES
(1, 2024, NULL, 3, 39, 10.00, 14.00, 0.00, 0.00, 24.00, 1, NULL, 'Demo', '2024-03-19 23:29:19', '2024-05-30 06:14:25'),
(2, 2024, NULL, 3, 40, 10.00, 14.00, 0.00, 0.00, 24.00, 1, NULL, 'Demo', '2024-03-19 23:29:19', '2024-03-19 23:29:19'),
(3, 2024, NULL, 3, 41, 10.00, 14.00, 0.00, 0.00, 24.00, 1, NULL, 'Demo', '2024-03-19 23:29:19', '2024-03-19 23:29:19'),
(5, 2024, NULL, 3, 43, 10.00, 14.00, 0.00, 0.00, 24.00, 1, '', ' ', '2024-03-24 01:50:56', '2024-03-24 01:50:56'),
(6, 2024, NULL, 4, 38, 10.00, 14.00, 0.00, 0.00, 24.00, 1, NULL, 'Demo', '2024-03-24 01:57:10', '2024-03-24 01:57:10'),
(7, 2024, NULL, 4, 44, 10.00, 14.00, 0.00, 0.00, 24.00, 1, NULL, 'Demo', '2024-03-24 01:57:10', '2024-03-24 01:57:10');

-- --------------------------------------------------------

--
-- Table structure for table `employee_ledgers`
--

CREATE TABLE `employee_ledgers` (
  `id` int(11) NOT NULL,
  `employee_id` int(11) DEFAULT NULL,
  `voucher_no` varchar(50) DEFAULT NULL,
  `ledger_title_id` int(11) DEFAULT NULL,
  `date` date DEFAULT NULL,
  `debit` decimal(18,2) DEFAULT NULL,
  `credit` decimal(18,2) DEFAULT NULL,
  `remarks` varchar(250) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `employee_ledgers`
--

INSERT INTO `employee_ledgers` (`id`, `employee_id`, `voucher_no`, `ledger_title_id`, `date`, `debit`, `credit`, `remarks`, `created_at`, `updated_at`) VALUES
(1, 1, 'VOU000001', 1, '2023-11-06', 0.00, 2000.00, 'Advance', '2023-11-06 04:04:11', '2023-11-06 04:04:11'),
(2, 1, 'VOU000002', 0, '2023-11-06', 1000.00, 0.00, 'Advance Return', '2023-11-06 04:04:26', '2023-11-06 04:04:26'),
(3, 1, 'VOU000003', 0, '2023-11-06', 200.00, 0.00, 'Advance Return', '2023-11-06 04:04:40', '2023-11-06 04:04:40'),
(4, 1, 'VOU000004', 1, '2023-11-06', 0.00, 700.00, 'Advance Return', '2023-11-06 04:04:58', '2023-11-06 04:04:58'),
(5, 2, 'VOU000005', 1, '2023-11-06', 0.00, 1000.00, 'Advance', '2023-11-06 04:05:17', '2023-11-06 04:05:17'),
(6, 2, 'VOU000006', 0, '2023-11-06', 200.00, 0.00, 'Advance Return', '2023-11-06 04:05:29', '2023-11-06 04:05:29'),
(7, 2, 'VOU000007', 1, '2023-11-06', 0.00, 500.00, 'Advance', '2023-11-06 04:05:40', '2023-11-06 04:05:40'),
(8, 3, 'VOU000008', 1, '2023-11-06', 0.00, 2000.00, 'Advance', '2023-11-06 04:05:59', '2023-11-06 04:05:59'),
(9, 3, 'VOU000009', 0, '2023-11-06', 500.00, 0.00, 'Advance Return', '2023-11-06 04:06:11', '2023-11-06 04:06:11');

-- --------------------------------------------------------

--
-- Table structure for table `employee_performances`
--

CREATE TABLE `employee_performances` (
  `id` int(10) UNSIGNED NOT NULL,
  `employee_id` int(10) UNSIGNED NOT NULL,
  `performance_date` date DEFAULT NULL,
  `performance_id` int(10) UNSIGNED NOT NULL,
  `performance_rate` decimal(4,2) UNSIGNED DEFAULT 0.00,
  `remarks` varchar(255) DEFAULT NULL,
  `done_by` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;

-- --------------------------------------------------------

--
-- Table structure for table `employee_salaries`
--

CREATE TABLE `employee_salaries` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `employee_id` int(11) NOT NULL,
  `amount` double(20,2) NOT NULL DEFAULT 0.00,
  `payslip_type` tinyint(4) DEFAULT 1,
  `start_date` date NOT NULL,
  `created_by` int(11) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;

--
-- Dumping data for table `employee_salaries`
--

INSERT INTO `employee_salaries` (`id`, `employee_id`, `amount`, `payslip_type`, `start_date`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 2, 20000.00, 1, '2023-09-01', 1, '2023-12-21 04:23:17', '2023-12-21 04:23:17'),
(2, 3, 30000.00, 1, '2023-08-01', 1, '2023-12-21 04:25:17', '2023-12-21 04:25:17'),
(3, 5, 35000.00, 1, '2023-08-01', 1, '2023-12-21 04:25:37', '2023-12-21 04:25:37'),
(4, 6, 40000.00, 1, '2023-08-01', 1, '2023-12-21 04:25:57', '2023-12-21 04:25:57');

-- --------------------------------------------------------

--
-- Table structure for table `emp_branches`
--

CREATE TABLE `emp_branches` (
  `id` int(11) NOT NULL,
  `branch_name` varchar(150) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `branch_code` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `branch_address` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `branch_mobile` varchar(150) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `branch_email` varchar(150) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `done_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `status` int(11) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `emp_branches`
--

INSERT INTO `emp_branches` (`id`, `branch_name`, `branch_code`, `branch_address`, `branch_mobile`, `branch_email`, `done_by`, `status`, `created_at`, `updated_at`) VALUES
(1, 'Branch 1', 'BC-001', 'Dhaka, Bangladesh', '01300000000', 'branch@branch.com', NULL, 1, '2023-02-12 01:24:19', '2024-02-25 01:37:21'),
(2, 'Branch 2', 'BC-002', 'Dhaka, Bangladesh', '01500000000', 'branch@branch.com', NULL, 0, '2023-02-12 02:47:45', '2024-02-25 01:37:29'),
(3, 'Branch 3', 'BC-003', 'Dhaka, Bangladesh', '01800000000', 'branch@branch.com', NULL, 0, '2023-02-12 03:06:35', '2024-02-25 01:37:37'),
(4, 'Factory', 'BC-004', 'Dhaka, Bangladesh', '01300000000', 'factory@gsl.com', NULL, 1, '2023-11-22 23:47:45', '2024-02-25 01:37:55');

-- --------------------------------------------------------

--
-- Table structure for table `emp_departments`
--

CREATE TABLE `emp_departments` (
  `id` int(11) NOT NULL,
  `branch_id` int(11) DEFAULT NULL,
  `department_name` varchar(150) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `department_name_bangla` varchar(150) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `status` int(11) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `emp_departments`
--

INSERT INTO `emp_departments` (`id`, `branch_id`, `department_name`, `department_name_bangla`, `status`, `created_at`, `updated_at`) VALUES
(1, 4, 'IT', NULL, 1, '2023-02-12 04:13:35', '2024-02-25 01:34:42'),
(2, 4, 'HR', NULL, 1, '2023-02-12 04:19:11', '2024-02-25 01:34:30'),
(3, 4, 'AC', NULL, 1, '2023-02-12 05:36:46', '2024-05-30 06:11:57'),
(6, 4, 'Department 1', NULL, 1, '2023-11-22 23:48:39', '2024-05-30 06:11:51'),
(7, NULL, 'Department', 'বিভাগ', 1, '2024-04-09 00:21:49', '2024-04-09 00:39:39');

-- --------------------------------------------------------

--
-- Table structure for table `emp_designations`
--

CREATE TABLE `emp_designations` (
  `id` int(11) NOT NULL,
  `designation_name` varchar(150) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `designation_name_bangla` varchar(150) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `status` int(11) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `emp_designations`
--

INSERT INTO `emp_designations` (`id`, `designation_name`, `designation_name_bangla`, `status`, `created_at`, `updated_at`) VALUES
(1, 'Programmer', NULL, 1, '2023-02-12 06:19:10', '2023-02-12 06:26:09'),
(2, 'Marketing', NULL, 1, '2023-09-19 02:23:24', '2024-05-30 06:11:40'),
(3, 'AC', NULL, 1, '2023-10-12 00:22:43', '2023-10-12 00:22:43'),
(4, 'HR', NULL, 1, '2023-11-22 23:48:52', '2023-11-22 23:48:52'),
(5, 'Manager', 'Name Bangla', 1, '2023-11-23 05:53:43', '2024-04-09 00:55:48');

-- --------------------------------------------------------

--
-- Table structure for table `emp_grades`
--

CREATE TABLE `emp_grades` (
  `id` int(11) NOT NULL,
  `grade_name` varchar(150) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `grade_name_bangla` varchar(150) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `status` int(11) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `emp_grades`
--

INSERT INTO `emp_grades` (`id`, `grade_name`, `grade_name_bangla`, `status`, `created_at`, `updated_at`) VALUES
(2, 'Grade English', 'বাংলা', 1, '2024-01-31 03:40:10', '2024-05-30 06:11:33');

-- --------------------------------------------------------

--
-- Table structure for table `emp_lines`
--

CREATE TABLE `emp_lines` (
  `id` int(11) NOT NULL,
  `line_name` varchar(150) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `line_name_bangla` varchar(150) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `status` int(11) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `emp_lines`
--

INSERT INTO `emp_lines` (`id`, `line_name`, `line_name_bangla`, `status`, `created_at`, `updated_at`) VALUES
(2, 'Line English', 'বাংলা', 1, '2024-01-31 02:05:07', '2024-05-30 06:13:28'),
(3, 'Line 1', NULL, 1, '2024-02-25 01:07:36', '2024-02-25 01:07:36');

-- --------------------------------------------------------

--
-- Table structure for table `emp_postings`
--

CREATE TABLE `emp_postings` (
  `id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `branch_id` int(11) DEFAULT 1,
  `type_id` int(11) DEFAULT NULL,
  `department_id` int(11) DEFAULT NULL,
  `section_id` int(11) DEFAULT NULL,
  `line_id` int(11) DEFAULT NULL,
  `designation_id` int(11) DEFAULT NULL,
  `grade_id` int(11) DEFAULT NULL,
  `gross_salary` decimal(10,0) DEFAULT 0,
  `ac_number` int(20) DEFAULT NULL,
  `salary_section_id` int(11) DEFAULT NULL,
  `joining_date` date DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `emp_postings`
--

INSERT INTO `emp_postings` (`id`, `employee_id`, `branch_id`, `type_id`, `department_id`, `section_id`, `line_id`, `designation_id`, `grade_id`, `gross_salary`, `ac_number`, `salary_section_id`, `joining_date`, `created_at`, `updated_at`) VALUES
(1, 38, 1, 5, 2, 4, 3, 5, 2, 50000, 100000001, 2, '2024-02-01', '2024-02-14 01:39:40', '2024-05-30 06:13:39'),
(2, 39, 1, 5, 1, 3, 2, 1, 2, 55555, 1546849687, 2, '2024-02-01', '2024-02-14 01:49:34', '2024-03-14 00:58:02'),
(3, 40, 1, 5, 1, 3, 2, 1, 2, 50000, 1445785875, 2, '2024-02-01', '2024-02-14 03:19:34', '2024-03-25 00:06:59'),
(4, 41, 1, 5, 2, 3, 2, 1, 2, 40000, 452345635, 2, '2024-02-01', '2024-02-14 03:23:48', '2024-03-14 00:58:34'),
(5, 43, 1, 7, 2, 3, 3, 2, 2, 30000, 216564518, 4, '2024-03-01', '2024-03-23 23:53:43', '2024-03-23 23:53:43'),
(6, 44, 1, 7, 1, 4, 3, 3, 2, 40000, 102521464, 4, '2024-03-01', '2024-03-24 00:08:44', '2024-04-17 02:44:34');

-- --------------------------------------------------------

--
-- Table structure for table `emp_quite_types`
--

CREATE TABLE `emp_quite_types` (
  `id` int(11) NOT NULL,
  `quite_type_name` varchar(150) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `quite_type_name_bangla` varchar(150) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `status` int(11) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `emp_quite_types`
--

INSERT INTO `emp_quite_types` (`id`, `quite_type_name`, `quite_type_name_bangla`, `status`, `created_at`, `updated_at`) VALUES
(2, 'Quite Type English', 'বাংলা', 1, '2024-02-01 03:38:50', '2024-02-01 04:10:51');

-- --------------------------------------------------------

--
-- Table structure for table `emp_salary_sections`
--

CREATE TABLE `emp_salary_sections` (
  `id` int(11) NOT NULL,
  `salary_section_name` varchar(150) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `salary_section_name_bangla` varchar(150) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `status` int(11) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `emp_salary_sections`
--

INSERT INTO `emp_salary_sections` (`id`, `salary_section_name`, `salary_section_name_bangla`, `status`, `created_at`, `updated_at`) VALUES
(2, 'Salary Section English', 'বাংলা', 1, '2024-01-31 05:04:23', '2024-02-01 04:10:58'),
(4, 'Salary Section Staff', NULL, 1, '2024-02-25 01:07:52', '2024-02-25 01:07:52');

-- --------------------------------------------------------

--
-- Table structure for table `emp_sections`
--

CREATE TABLE `emp_sections` (
  `id` int(11) NOT NULL,
  `section_name` varchar(150) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `section_name_bangla` varchar(150) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `status` int(11) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `emp_sections`
--

INSERT INTO `emp_sections` (`id`, `section_name`, `section_name_bangla`, `status`, `created_at`, `updated_at`) VALUES
(3, 'Section 1', 'বাংলা', 1, '2024-01-31 01:52:57', '2024-03-19 01:58:16'),
(4, 'Section 2', NULL, 1, '2024-02-25 01:07:28', '2024-05-30 06:09:17');

-- --------------------------------------------------------

--
-- Table structure for table `emp_types`
--

CREATE TABLE `emp_types` (
  `id` int(11) NOT NULL,
  `type_name` varchar(150) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `type_name_bangla` varchar(150) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `status` int(11) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `emp_types`
--

INSERT INTO `emp_types` (`id`, `type_name`, `type_name_bangla`, `status`, `created_at`, `updated_at`) VALUES
(5, 'Type English', 'টাইপ বাংলা', 1, '2024-01-31 00:39:50', '2024-02-01 03:53:01'),
(7, 'Staff', NULL, 1, '2024-02-25 01:06:40', '2024-05-30 06:11:44'),
(8, 'Worker', NULL, 1, '2024-02-25 01:07:18', '2024-05-30 05:23:48');

-- --------------------------------------------------------

--
-- Table structure for table `failed_jobs`
--

CREATE TABLE `failed_jobs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `uuid` varchar(191) NOT NULL,
  `connection` text NOT NULL,
  `queue` text NOT NULL,
  `payload` longtext NOT NULL,
  `exception` longtext NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `finance_accounts`
--

CREATE TABLE `finance_accounts` (
  `id` int(11) UNSIGNED NOT NULL,
  `financegroup_id` int(11) DEFAULT NULL,
  `account_company_code` varchar(200) DEFAULT NULL,
  `account_name` varchar(150) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `account_mobile` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `account_email` varchar(100) DEFAULT NULL,
  `account_address` varchar(200) DEFAULT NULL,
  `account_group_code` varchar(150) DEFAULT NULL,
  `account_status` int(11) DEFAULT 0,
  `account_done_by` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `account_updated_by` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `finance_accounts`
--

INSERT INTO `finance_accounts` (`id`, `financegroup_id`, `account_company_code`, `account_name`, `account_mobile`, `account_email`, `account_address`, `account_group_code`, `account_status`, `account_done_by`, `account_updated_by`, `created_at`, `updated_at`) VALUES
(7, 2, '01', 'Speed Money', NULL, NULL, NULL, '2', 1, 'Demo', NULL, '2024-05-14 05:49:36', '2024-05-14 05:49:36'),
(8, 6, '01', 'Current Asset Cash', NULL, NULL, NULL, NULL, 1, 'Demo', NULL, '2024-05-14 05:51:46', '2024-09-05 07:46:41'),
(9, 3, '01', 'Rent from Gulshan Land', NULL, NULL, NULL, '3', 1, 'Demo', NULL, '2024-05-14 05:58:26', '2024-05-14 05:58:26'),
(11, 13, '01', 'Cash', NULL, NULL, NULL, '100020002', 1, 'Demo', NULL, '2024-05-26 07:32:03', '2024-09-05 07:46:54'),
(12, 14, '01', 'bKash : 01580026521', NULL, NULL, NULL, '100020003', 1, 'Demo', NULL, '2024-05-26 07:45:31', '2024-09-05 07:48:05'),
(13, 2, '01', 'Purchase Account', NULL, NULL, NULL, '2', 1, 'Demo', NULL, '2024-05-26 09:46:56', '2024-05-26 09:46:56'),
(14, 3, '01', 'Sales Account', NULL, NULL, NULL, '3', 1, 'Demo', NULL, '2024-05-29 11:10:39', '2024-05-29 11:10:39'),
(22, 15, '01', 'Shahjalal Islami Bank A/C: 0145256', NULL, NULL, NULL, '100020004', 1, 'Demo', NULL, '2024-06-12 13:24:48', '2024-09-05 07:47:31'),
(106, 15, '01', 'Dutch Bangla Bank A/C: 123456', NULL, NULL, NULL, '100020004', 1, 'Demo', NULL, '2024-09-08 04:41:10', '2024-09-08 04:41:10'),
(107, 11, '01', 'Supplier 1', '01681952638', NULL, 'Dhaka, Bangladesh', '400010001', 1, 'Admin', NULL, '2024-09-11 12:47:09', '2024-09-12 05:28:08'),
(108, 7, '01', 'Customer 1', '01681952638', NULL, 'Dhaka, Bangladesh', '100020001', 1, 'Admin', NULL, '2024-09-11 12:48:20', '2024-09-12 05:28:44'),
(109, 11, '01', 'Supplier 2', '01681952638', NULL, 'Gulshan, Dhaka, Bangladesh', '400010001', 1, 'Admin', 'Demo', '2024-09-12 05:28:28', '2024-11-12 18:49:57'),
(110, 7, '01', 'Customer 2', '0152264596', NULL, 'Dhaka, Bangladesh', '100020001', 1, 'Admin', NULL, '2024-09-12 05:29:07', '2024-09-12 05:29:07'),
(111, 7, '01', 'MRS Sabrina', '01789869140', NULL, 'mirpur, dhaka', '100020001', 1, 'Admin', NULL, '2024-09-17 22:12:29', '2024-09-17 22:12:29'),
(112, 11, '01', 'ABM engineering', '01841350351', NULL, 'mirpur', '400010001', 1, 'Admin', NULL, '2024-09-17 22:13:39', '2024-09-17 22:13:39'),
(113, 7, '01', 'Dr. Sabrina Rahman', '01733722480', NULL, 'kazipara, mirpur Dhaka', '100020001', 1, 'Admin', NULL, '2024-09-24 17:15:01', '2024-09-24 17:15:01'),
(114, 7, '01', 'Md. Ashraf', '0171-8807815', NULL, 'mirpur, dhaka', '100020001', 1, 'Admin', 'Admin', '2024-09-26 23:21:53', '2024-10-30 18:15:54'),
(115, 7, '01', 'Mr Sabbir', '0162009339', NULL, '51/A North Road.', '100020001', 1, 'Admin', NULL, '2024-09-27 00:12:00', '2024-09-27 00:12:00'),
(116, 7, '01', 'Jihad Juice and fast Food.', '01815429270', NULL, '63 B Green Road( K M Fojiullah Road)', '100020001', 1, 'Admin', NULL, '2024-09-27 00:14:13', '2024-09-27 00:14:13'),
(117, 7, '01', 'Mr Rupon', '01619056367', NULL, 'Novana Tower.', '100020001', 1, 'Admin', NULL, '2024-09-27 00:17:06', '2024-09-27 00:17:06'),
(118, 7, '01', 'Mr Monir Hossain.', '01911421255', NULL, 'Plot-12,Road,6,2ndFloor,Senpura Mirpur-10.', '100020001', 1, 'Admin', NULL, '2024-09-27 00:19:38', '2024-09-27 00:19:38'),
(119, 7, '01', 'Mr Raju', '01705018687', NULL, 'Banani,Dhaka.', '100020001', 1, 'Admin', NULL, '2024-09-27 00:20:31', '2024-09-27 00:20:31'),
(120, 7, '01', 'Md Tanvir.', '01684771151', NULL, 'Uttora', '100020001', 1, 'Admin', NULL, '2024-09-27 00:21:21', '2024-09-27 00:21:21'),
(121, 7, '01', 'Mr Feroz Alam', '01715253166', NULL, 'Saddam Paper House', '100020001', 1, 'Admin', NULL, '2024-09-27 00:22:20', '2024-09-27 00:22:20'),
(122, 7, '01', 'Jafor Raja', '01711334612', NULL, 'H-295,R-19/B,Mahakhali.', '100020001', 1, 'Admin', NULL, '2024-09-27 00:23:41', '2024-09-27 00:23:41'),
(123, 7, '01', 'Md Alamgir', '01678012177', NULL, 'Mirpur-10,Dhaka.', '100020001', 1, 'Admin', NULL, '2024-09-27 00:35:43', '2024-09-27 00:35:43'),
(124, 7, '01', 'Nur Al Mahedi.', '01709452377', NULL, 'Mirpur,Dhaka.', '100020001', 1, 'Admin', NULL, '2024-09-27 00:41:06', '2024-09-27 00:41:06'),
(125, 7, '01', 'Md Saiful islam.', '01787107774', NULL, 'Jattrabari', '100020001', 1, 'Admin', NULL, '2024-09-27 00:43:15', '2024-09-27 00:43:15'),
(126, 7, '01', 'Mr Habibur', '01721797806', NULL, 'Kollyanpur', '100020001', 1, 'Admin', NULL, '2024-09-27 00:46:25', '2024-09-27 00:46:25'),
(127, 7, '01', 'Mr Tanvir (  Rubel Acc)', '01723619177', NULL, 'Mirpur-1', '100020001', 1, 'Admin', NULL, '2024-09-27 00:47:24', '2024-09-27 00:47:24'),
(128, 7, '01', 'Md Ziaul Haque(Zia Sir)', '01751526984', NULL, 'Shobhanbug govt stuff Quater', '100020001', 1, 'Admin', NULL, '2024-09-27 00:49:06', '2024-09-28 20:26:58'),
(129, 7, '01', 'Shahanaz Bristy', '01724928335', NULL, 'Mirpur 12 ,Dhaka.', '100020001', 1, 'Admin', NULL, '2024-09-27 00:50:26', '2024-09-27 00:50:26'),
(130, 7, '01', 'Mr Emon', '01678012173', NULL, 'Malibag,Dhaka.', '100020001', 1, 'Admin', NULL, '2024-09-27 00:52:06', '2024-09-27 00:52:06'),
(131, 7, '01', 'Joy', '01754242658', NULL, 'Dhammondi,8A.', '100020001', 1, 'Admin', NULL, '2024-09-27 00:54:51', '2024-09-27 00:54:51'),
(132, 7, '01', 'Mr Soriful Islam', '01711299071', NULL, 'Mirpur', '100020001', 1, 'Admin', NULL, '2024-09-27 00:55:58', '2024-09-28 19:28:41'),
(133, 7, '01', 'Sohel (Zia sir)', '01754577743', NULL, 'Pirerbug, Mirpur -2.', '100020001', 1, 'Admin', NULL, '2024-09-28 16:29:37', '2024-09-28 16:29:37'),
(134, 7, '01', 'Mrs. Pinky.', '01684568800', NULL, 'Shekhentek,RD-3.', '100020001', 1, 'Admin', NULL, '2024-09-28 16:33:23', '2024-09-28 16:33:23'),
(135, 7, '01', 'Md Hossain Ahmed', '01780448844', NULL, 'Shankar,Dhanmondi, Dhaka.', '100020001', 1, 'Admin', NULL, '2024-09-28 16:41:45', '2024-09-28 16:41:45'),
(136, 7, '01', 'Ms Najnin.', '01960405618', NULL, '19/4 Uttar Tolarbug.', '100020001', 1, 'Admin', NULL, '2024-09-28 16:43:54', '2024-09-28 16:43:54'),
(137, 7, '01', 'Shakwat Rahim  Khan.', '01716-411860', NULL, 'Dhanmondi 15.', '100020001', 1, 'Admin', NULL, '2024-09-28 16:46:37', '2024-09-28 16:46:37'),
(138, 7, '01', 'Mr Robiul.', '01754-858644', NULL, 'Sobujbag,Dhaka.', '100020001', 1, 'Admin', NULL, '2024-09-28 16:49:43', '2024-09-28 17:42:51'),
(139, 7, '01', 'Abir', '01723-619177.', NULL, 'Mugdapara,Dhaka.', '100020001', 1, 'Admin', NULL, '2024-09-28 16:51:07', '2024-09-28 16:51:07'),
(140, 7, '01', 'Mr Adnan', '01732-525888', NULL, 'Ibrahimpur.', '100020001', 1, 'Admin', NULL, '2024-09-28 16:53:52', '2024-09-28 16:53:52'),
(141, 7, '01', 'Mr Ashraful.', '01980301353', NULL, 'Rupnagor,Eslarp Aousing, Mirpur 12.', '100020001', 1, 'Admin', NULL, '2024-09-28 16:56:58', '2024-09-28 16:56:58'),
(142, 7, '01', 'Sonali Paper and Board Mills.', '01896047230', NULL, 'Dhanmondi, Central Road.', '100020001', 1, 'Admin', NULL, '2024-09-28 18:59:58', '2024-09-28 18:59:58'),
(143, 7, '01', 'Md Alomgir Sir.', '016788012177', NULL, 'Mirpur 10.', '100020001', 1, 'Admin', NULL, '2024-09-28 20:24:05', '2024-09-28 20:24:05'),
(144, 7, '01', 'Mr Monu.', '01911424255', NULL, 'Mirpur-13.', '100020001', 1, 'Admin', NULL, '2024-09-28 21:14:25', '2024-09-28 21:14:25'),
(145, 7, '01', 'Sonali Paper  Mill Head Office Centeen.', '01896047230', NULL, 'Dhanmondi Central road.', '100020001', 1, 'Admin', NULL, '2024-09-28 21:39:41', '2024-09-28 21:39:41'),
(146, 7, '01', 'Istiaque Ahmed', '01715070700', NULL, 'Banglamotor', '100020001', 1, 'Admin', NULL, '2024-09-28 21:45:50', '2024-09-28 21:45:50'),
(147, 7, '01', 'Md Lokman Hossain.', '01678020868', NULL, 'Tarabo Rupgong , Narayangang.', '100020001', 1, 'Admin', NULL, '2024-09-28 21:47:18', '2024-09-28 21:47:18'),
(148, 7, '01', 'Md Monir.', '01624-356814', NULL, 'Mirpur-10,Road 6,P-12.', '100020001', 1, 'Admin', NULL, '2024-09-28 22:17:43', '2024-09-28 22:17:43'),
(149, 7, '01', 'Md Somrath.', '01324356987', NULL, 'Mirpur-1, F Block.', '100020001', 1, 'Admin', NULL, '2024-09-28 22:19:14', '2024-09-28 22:19:14'),
(150, 7, '01', 'Dr. Tahseen Ali.', '01762-806646', NULL, 'House-06, Park Road, Baridhara D. Zone.', '100020001', 1, 'Admin', NULL, '2024-10-01 14:19:52', '2024-10-01 14:19:52'),
(151, 7, '01', 'Md.Liton', '01737515273', NULL, 'Boro Kusherbag,Jinjira keranigong.', '100020001', 1, 'Admin', NULL, '2024-10-06 23:37:30', '2024-10-06 23:37:30'),
(152, 7, '01', 'Khorshed', '01732-988324.', NULL, 'Noya Bajar, Jindabahar,Police Fari Goli.', '100020001', 1, 'Admin', NULL, '2024-10-06 23:40:02', '2024-10-06 23:40:02'),
(153, 7, '01', 'AKM Haruner Rashid', '01711105322', NULL, 'Swami bag behind Mitali School.', '100020001', 1, 'Admin', 'Admin', '2024-10-16 23:18:43', '2024-10-30 18:09:06'),
(154, 7, '01', 'Mr. Shimul', '01735666301', NULL, 'Shewrapara,Ibrahimpur,Kamal khan Road.', '100020001', 1, 'Admin', 'Admin', '2024-10-19 22:37:05', '2024-10-30 17:20:24'),
(158, 7, '01', 'Exim Bank', '01611-954442', NULL, 'Noyerhat, Savar.', '100020001', 1, 'Admin', 'Demo', '2024-10-30 17:48:33', '2024-11-12 18:44:08'),
(159, 7, '01', 'Mrs. Nazma', '01309312356', NULL, 'Mirpur 2, Pirerbag', '100020001', 1, 'Admin', NULL, '2024-11-19 22:13:59', '2024-11-19 22:13:59'),
(160, 7, '01', 'Muza Wasin', '0171129410', NULL, 'Baily Road, Viqarunnisa', '100020001', 1, 'Admin', NULL, '2024-11-19 22:22:46', '2024-11-19 22:22:46'),
(161, 7, '01', 'BD Unani & Ayurbedic', '01712-564542', NULL, 'Indira Road, Farmgate', '100020001', 1, 'Admin', NULL, '2024-11-19 22:28:13', '2024-11-19 22:28:13'),
(162, 7, '01', 'MD Jahid Hasan', '01755-565656', NULL, 'Noyabazar', '100020001', 1, 'Admin', NULL, '2024-11-19 22:35:26', '2024-11-19 22:35:26'),
(163, 7, '01', 'MD Soleman', '01705-736088', NULL, 'Dhanmondi 1', '100020001', 1, 'Admin', NULL, '2024-11-19 22:49:19', '2024-11-19 22:49:19'),
(164, 7, '01', 'MD Rakib Ali', '01777-777777', NULL, 'Kodomtoli', '100020001', 1, 'Admin', NULL, '2024-11-19 22:52:38', '2024-11-19 22:52:38'),
(165, 7, '01', 'Mr Habib', '01777-777777', NULL, 'Dhanmondi- 06', '100020001', 1, 'Admin', NULL, '2024-11-19 22:56:25', '2024-11-19 22:56:25'),
(166, 7, '01', 'Shadat Hasan', '01833-673299', NULL, NULL, '100020001', 1, 'Admin', NULL, '2024-11-19 23:05:22', '2024-11-19 23:05:22'),
(167, 7, '01', 'MD limon', '01711-299071', NULL, NULL, '100020001', 1, 'Admin', NULL, '2024-11-23 22:30:48', '2024-11-23 22:30:48'),
(168, 7, '01', 'Md Junayed Hossain', '01761-193501', NULL, '65 Elephant Road', '100020001', 1, 'Admin', NULL, '2024-11-26 22:14:41', '2024-11-26 22:14:41');

-- --------------------------------------------------------

--
-- Table structure for table `finance_groups`
--

CREATE TABLE `finance_groups` (
  `id` int(11) UNSIGNED NOT NULL,
  `group_code` varchar(150) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `group_name` varchar(150) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `group_parents` varchar(150) DEFAULT '0',
  `group_company_code` varchar(200) DEFAULT NULL,
  `group_status` int(11) DEFAULT 0,
  `group_done_by` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `group_updated_by` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `finance_groups`
--

INSERT INTO `finance_groups` (`id`, `group_code`, `group_name`, `group_parents`, `group_company_code`, `group_status`, `group_done_by`, `group_updated_by`, `created_at`, `updated_at`) VALUES
(1, '1', 'Assets', 'ROOT', '01', 1, 'Demo', NULL, '2024-05-08 03:07:03', '2024-05-08 03:07:03'),
(2, '2', 'Expenses', 'ROOT', '01', 1, 'Demo', NULL, '2024-05-08 03:10:07', '2024-05-08 03:10:07'),
(3, '3', 'Income', 'ROOT', '01', 1, 'Demo', NULL, '2024-05-08 03:10:23', '2024-05-08 03:10:23'),
(4, '4', 'Liabilities', 'ROOT', '01', 1, 'Demo', NULL, '2024-05-08 03:10:37', '2024-05-08 03:10:37'),
(5, '10001', 'Fixed Asset', '1', '01', 1, 'Demo', NULL, '2024-05-08 03:12:28', '2024-05-08 03:12:28'),
(6, '10002', 'Current Asset', '1', '01', 1, 'Demo', NULL, '2024-05-08 03:12:55', '2024-05-08 03:12:55'),
(7, '100020001', 'Account Receivable', '10002', '01', 1, 'Demo', NULL, '2024-05-08 03:17:19', '2024-05-08 03:17:19'),
(9, '100010001', 'Land', '10001', '01', 1, 'Demo', NULL, '2024-05-08 06:23:16', '2024-05-08 06:23:16'),
(10, '40001', 'Current Liabilities', '4', '01', 1, 'Demo', NULL, '2024-05-09 06:24:05', '2024-05-09 06:24:05'),
(11, '400010001', 'Account Payable', '40001', '01', 1, 'Demo', NULL, '2024-05-12 05:44:58', '2024-05-12 05:44:58'),
(12, '100010002', 'Gulshan Land', '10001', '01', 1, 'Demo', NULL, '2024-05-14 05:40:33', '2024-05-14 05:40:33'),
(13, '100020002', 'Cash in hand', '10002', '01', 1, 'Demo', NULL, '2024-05-26 07:15:34', '2024-05-26 07:15:34'),
(14, '100020003', 'Mobile Bank', '10002', '01', 1, 'Demo', NULL, '2024-05-26 07:45:04', '2024-05-26 07:45:04'),
(15, '100020004', 'Bank Account', '10002', '01', 1, 'Demo', NULL, '2024-06-12 13:23:45', '2024-06-12 13:23:45');

-- --------------------------------------------------------

--
-- Table structure for table `finance_transactions`
--

CREATE TABLE `finance_transactions` (
  `id` int(11) UNSIGNED NOT NULL,
  `company_code` varchar(200) DEFAULT NULL,
  `delivery_challan_no` varchar(200) DEFAULT NULL,
  `invoice_no` varchar(200) DEFAULT NULL,
  `voucher_no` varchar(200) DEFAULT NULL,
  `voucher_date` date DEFAULT NULL,
  `acid` int(11) DEFAULT NULL,
  `to_acc_name` varchar(150) DEFAULT NULL,
  `type` varchar(120) DEFAULT NULL,
  `amount` decimal(20,2) DEFAULT 0.00,
  `balance_type` varchar(120) DEFAULT NULL,
  `payment_type` varchar(155) DEFAULT NULL,
  `narration` text DEFAULT NULL,
  `cheque_no` varchar(100) DEFAULT NULL,
  `cheque_date` date DEFAULT NULL,
  `cheque_type` varchar(100) DEFAULT NULL,
  `transaction_date` date DEFAULT NULL,
  `transaction_by` varchar(100) DEFAULT NULL,
  `invoice_type` int(11) DEFAULT NULL,
  `pending_adjustment` varchar(200) DEFAULT NULL,
  `status` int(11) DEFAULT 0,
  `done_by` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `updated_by` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `finance_transactions`
--

INSERT INTO `finance_transactions` (`id`, `company_code`, `delivery_challan_no`, `invoice_no`, `voucher_no`, `voucher_date`, `acid`, `to_acc_name`, `type`, `amount`, `balance_type`, `payment_type`, `narration`, `cheque_no`, `cheque_date`, `cheque_type`, `transaction_date`, `transaction_by`, `invoice_type`, `pending_adjustment`, `status`, `done_by`, `updated_by`, `created_at`, `updated_at`) VALUES
(17, '01', 'CHA000001', 'INV000001', '01SV000001', '2024-04-02', 113, 'Sales Account', 'SV', 4000.00, 'Dr', NULL, 'Invoice:INV000001, Name:DF-105, Qty:1 X 4000.00\n', NULL, NULL, NULL, '2024-04-02', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-09-25 09:47:56', '2024-09-24 17:19:55'),
(18, '01', 'CHA000001', 'INV000001', '01SV000001', '2024-04-02', 14, 'Dr. Sabrina Rahman', 'SV', 4000.00, 'Cr', NULL, 'Invoice:INV000001, Name:DF-105, Qty:1 X 4000.00\n', NULL, NULL, NULL, '2024-04-02', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-09-25 09:47:52', '2024-09-24 17:19:55'),
(19, '01', 'CHA000001', 'INV000001', '01SV000001', '2024-04-02', 113, 'Cash', 'SV', 4000.00, 'Cr', 'Cash', 'Invoice:INV000001, Cash Received From: Dr. Sabrina Rahman, Through Cash Paid Amount:4,000.00 TK\n', NULL, NULL, NULL, '2024-04-02', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-09-25 09:47:48', '2024-09-24 17:19:55'),
(20, '01', 'CHA000001', 'INV000001', '01SV000001', '2024-04-02', 11, 'Dr. Sabrina Rahman', 'SV', 4000.00, 'Dr', 'Cash', 'Invoice:INV000001, Cash Received From: Dr. Sabrina Rahman, Through Cash Paid Amount:4,000.00 TK\n', NULL, NULL, NULL, '2024-04-02', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-09-25 09:47:44', '2024-09-24 17:19:55'),
(197, '01', 'CHA000005', 'INV000005', '01SV000005', '2024-04-06', 114, 'Sales Account', 'SV', 9500.00, 'Dr', NULL, 'Invoice:INV000005, Name:RO-105, Qty:1 X 10900.00\n', NULL, NULL, NULL, '2024-04-06', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 14:59:58', '2024-10-01 14:59:58'),
(198, '01', 'CHA000005', 'INV000005', '01SV000005', '2024-04-06', 14, 'Md. Asraf', 'SV', 9500.00, 'Cr', NULL, 'Invoice:INV000005, Name:RO-105, Qty:1 X 10900.00\n', NULL, NULL, NULL, '2024-04-06', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 14:59:58', '2024-10-01 14:59:58'),
(199, '01', 'CHA000005', 'INV000005', '01SV000005', '2024-04-06', 114, 'Cash', 'SV', 9500.00, 'Cr', 'Cash', 'Invoice:INV000005, Cash Received From: Md. Asraf, Through Cash Paid Amount:9,500.00 TK\n', NULL, NULL, NULL, '2024-04-06', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 14:59:58', '2024-10-01 14:59:58'),
(200, '01', 'CHA000005', 'INV000005', '01SV000005', '2024-04-06', 11, 'Md. Asraf', 'SV', 9500.00, 'Dr', 'Cash', 'Invoice:INV000005, Cash Received From: Md. Asraf, Through Cash Paid Amount:9,500.00 TK\n', NULL, NULL, NULL, '2024-04-06', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 14:59:58', '2024-10-01 14:59:58'),
(213, '01', 'CHA000008', 'INV000008', '01SV000008', '2024-04-29', 118, 'Sales Account', 'SV', 9750.00, 'Dr', NULL, 'Invoice:INV000008, Name:RO-105, Qty:1.00 X 11500.00\n\nName:6mm Pipe., Qty:25.00 X 10.00\n', NULL, NULL, NULL, '2024-04-29', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 15:16:06', '2024-10-01 15:16:06'),
(214, '01', 'CHA000008', 'INV000008', '01SV000008', '2024-04-29', 14, 'Mr Monir Hossain.', 'SV', 9750.00, 'Cr', NULL, 'Invoice:INV000008, Name:RO-105, Qty:1.00 X 11500.00\n\nName:6mm Pipe., Qty:25.00 X 10.00\n', NULL, NULL, NULL, '2024-04-29', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 15:16:06', '2024-10-01 15:16:06'),
(215, '01', 'CHA000008', 'INV000008', '01SV000008', '2024-04-29', 118, 'Cash', 'SV', 9750.00, 'Cr', 'Cash', 'Invoice:INV000008, Cash Received From: Mr Monir Hossain., Through Cash Paid Amount:9,750.00 TK\n', NULL, NULL, NULL, '2024-04-29', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 15:16:06', '2024-10-01 15:16:06'),
(216, '01', 'CHA000008', 'INV000008', '01SV000008', '2024-04-29', 11, 'Mr Monir Hossain.', 'SV', 9750.00, 'Dr', 'Cash', 'Invoice:INV000008, Cash Received From: Mr Monir Hossain., Through Cash Paid Amount:9,750.00 TK\n', NULL, NULL, NULL, '2024-04-29', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 15:16:06', '2024-10-01 15:16:06'),
(217, '01', 'CHA000007', 'INV000007', '01SV000007', '2024-04-25', 117, 'Sales Account', 'SV', 11900.00, 'Dr', NULL, 'Invoice:INV000007, Name:RO-105, Qty:1.00 X 11500.00\n\nName:6mm Pipe., Qty:40.00 X 10.00\n', NULL, NULL, NULL, '2024-04-25', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 15:16:52', '2024-10-01 15:16:52'),
(218, '01', 'CHA000007', 'INV000007', '01SV000007', '2024-04-25', 14, 'Mr Rupon', 'SV', 11900.00, 'Cr', NULL, 'Invoice:INV000007, Name:RO-105, Qty:1.00 X 11500.00\n\nName:6mm Pipe., Qty:40.00 X 10.00\n', NULL, NULL, NULL, '2024-04-25', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 15:16:52', '2024-10-01 15:16:52'),
(225, '01', 'CHA000009', 'INV000009', '01SV000009', '2024-04-30', 119, 'Sales Account', 'SV', 9500.00, 'Dr', NULL, 'Invoice:INV000009, Name:RO-105, Qty:1.00 X 11500.00\n', NULL, NULL, NULL, '2024-04-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 15:24:34', '2024-10-01 15:24:34'),
(226, '01', 'CHA000009', 'INV000009', '01SV000009', '2024-04-30', 14, 'Mr Raju', 'SV', 9500.00, 'Cr', NULL, 'Invoice:INV000009, Name:RO-105, Qty:1.00 X 11500.00\n', NULL, NULL, NULL, '2024-04-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 15:24:34', '2024-10-01 15:24:34'),
(227, '01', 'CHA000009', 'INV000009', '01SV000009', '2024-04-30', 119, 'Cash', 'SV', 9500.00, 'Cr', 'Cash', 'Invoice:INV000009, Cash Received From: Mr Raju, Through Cash Paid Amount:9,500.00 TK\n', NULL, NULL, NULL, '2024-04-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 15:24:34', '2024-10-01 15:24:34'),
(228, '01', 'CHA000009', 'INV000009', '01SV000009', '2024-04-30', 11, 'Mr Raju', 'SV', 9500.00, 'Dr', 'Cash', 'Invoice:INV000009, Cash Received From: Mr Raju, Through Cash Paid Amount:9,500.00 TK\n', NULL, NULL, NULL, '2024-04-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 15:24:34', '2024-10-01 15:24:34'),
(229, '01', 'CHA000010', 'INV000010', '01SV000010', '2024-04-23', 120, 'Sales Account', 'SV', 8000.00, 'Dr', NULL, 'Invoice:INV000010, Name:DF-105, Qty:2.00 X 4000.00\n', NULL, NULL, NULL, '2024-04-23', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 15:26:00', '2024-10-01 15:26:00'),
(230, '01', 'CHA000010', 'INV000010', '01SV000010', '2024-04-23', 14, 'Md Tanvir.', 'SV', 8000.00, 'Cr', NULL, 'Invoice:INV000010, Name:DF-105, Qty:2.00 X 4000.00\n', NULL, NULL, NULL, '2024-04-23', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 15:26:00', '2024-10-01 15:26:00'),
(231, '01', 'CHA000010', 'INV000010', '01SV000010', '2024-04-23', 120, 'Cash', 'SV', 8000.00, 'Cr', 'Cash', 'Invoice:INV000010, Cash Received From: Md Tanvir., Through Cash Paid Amount:8,000.00 TK\n', NULL, NULL, NULL, '2024-04-23', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 15:26:00', '2024-10-01 15:26:00'),
(232, '01', 'CHA000010', 'INV000010', '01SV000010', '2024-04-23', 11, 'Md Tanvir.', 'SV', 8000.00, 'Dr', 'Cash', 'Invoice:INV000010, Cash Received From: Md Tanvir., Through Cash Paid Amount:8,000.00 TK\n', NULL, NULL, NULL, '2024-04-23', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 15:26:00', '2024-10-01 15:26:00'),
(237, '01', 'CHA000012', 'INV000012', '01SV000012', '2024-05-06', 122, 'Sales Account', 'SV', 9600.00, 'Dr', NULL, 'Invoice:INV000012, Name:RO-105, Qty:1.00 X 11500.00\n\nName:6mm Pipe., Qty:10.00 X 10.00\n', NULL, NULL, NULL, '2024-05-06', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 15:29:35', '2024-10-01 15:29:35'),
(238, '01', 'CHA000012', 'INV000012', '01SV000012', '2024-05-06', 14, 'Jafor Raja', 'SV', 9600.00, 'Cr', NULL, 'Invoice:INV000012, Name:RO-105, Qty:1.00 X 11500.00\n\nName:6mm Pipe., Qty:10.00 X 10.00\n', NULL, NULL, NULL, '2024-05-06', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 15:29:35', '2024-10-01 15:29:35'),
(239, '01', 'CHA000012', 'INV000012', '01SV000012', '2024-05-06', 122, 'Cash', 'SV', 9600.00, 'Cr', 'Cash', 'Invoice:INV000012, Cash Received From: Jafor Raja, Through Cash Paid Amount:9,600.00 TK\n', NULL, NULL, NULL, '2024-05-06', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 15:29:35', '2024-10-01 15:29:35'),
(240, '01', 'CHA000012', 'INV000012', '01SV000012', '2024-05-06', 11, 'Jafor Raja', 'SV', 9600.00, 'Dr', 'Cash', 'Invoice:INV000012, Cash Received From: Jafor Raja, Through Cash Paid Amount:9,600.00 TK\n', NULL, NULL, NULL, '2024-05-06', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 15:29:35', '2024-10-01 15:29:35'),
(241, '01', 'CHA000013', 'INV000013', '01SV000013', '2024-05-07', 123, 'Sales Account', 'SV', 9600.00, 'Dr', NULL, 'Invoice:INV000013, Name:RO-105, Qty:1.00 X 11500.00\n\nName:6mm Pipe., Qty:10.00 X 10.00\n', NULL, NULL, NULL, '2024-05-07', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:27:43', '2024-10-01 16:27:43'),
(242, '01', 'CHA000013', 'INV000013', '01SV000013', '2024-05-07', 14, 'Md Alamgir', 'SV', 9600.00, 'Cr', NULL, 'Invoice:INV000013, Name:RO-105, Qty:1.00 X 11500.00\n\nName:6mm Pipe., Qty:10.00 X 10.00\n', NULL, NULL, NULL, '2024-05-07', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:27:43', '2024-10-01 16:27:43'),
(243, '01', 'CHA000013', 'INV000013', '01SV000013', '2024-05-07', 123, 'Cash', 'SV', 9600.00, 'Cr', 'Cash', 'Invoice:INV000013, Cash Received From: Md Alamgir, Through Cash Paid Amount:9,600.00 TK\n', NULL, NULL, NULL, '2024-05-07', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:27:43', '2024-10-01 16:27:43'),
(244, '01', 'CHA000013', 'INV000013', '01SV000013', '2024-05-07', 11, 'Md Alamgir', 'SV', 9600.00, 'Dr', 'Cash', 'Invoice:INV000013, Cash Received From: Md Alamgir, Through Cash Paid Amount:9,600.00 TK\n', NULL, NULL, NULL, '2024-05-07', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:27:43', '2024-10-01 16:27:43'),
(245, '01', 'CHA000014', 'INV000014', '01SV000014', '2024-05-08', 124, 'Sales Account', 'SV', 4000.00, 'Dr', NULL, 'Invoice:INV000014, Name:DF-105, Qty:1.00 X 5000.00\n', NULL, NULL, NULL, '2024-05-08', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:29:58', '2024-10-01 16:29:58'),
(246, '01', 'CHA000014', 'INV000014', '01SV000014', '2024-05-08', 14, 'Nur Al Mahedi.', 'SV', 4000.00, 'Cr', NULL, 'Invoice:INV000014, Name:DF-105, Qty:1.00 X 5000.00\n', NULL, NULL, NULL, '2024-05-08', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:29:58', '2024-10-01 16:29:58'),
(247, '01', 'CHA000014', 'INV000014', '01SV000014', '2024-05-08', 124, 'Cash', 'SV', 4000.00, 'Cr', 'Cash', 'Invoice:INV000014, Cash Received From: Nur Al Mahedi., Through Cash Paid Amount:4,000.00 TK\n', NULL, NULL, NULL, '2024-05-08', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:29:58', '2024-10-01 16:29:58'),
(248, '01', 'CHA000014', 'INV000014', '01SV000014', '2024-05-08', 11, 'Nur Al Mahedi.', 'SV', 4000.00, 'Dr', 'Cash', 'Invoice:INV000014, Cash Received From: Nur Al Mahedi., Through Cash Paid Amount:4,000.00 TK\n', NULL, NULL, NULL, '2024-05-08', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:29:58', '2024-10-01 16:29:58'),
(249, '01', 'CHA000015', 'INV000015', '01SV000015', '2024-05-08', 125, 'Sales Account', 'SV', 9500.00, 'Dr', NULL, 'Invoice:INV000015, Name:RO-105, Qty:1.00 X 11500.00\n', NULL, NULL, NULL, '2024-05-08', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:33:39', '2024-10-01 16:33:39'),
(250, '01', 'CHA000015', 'INV000015', '01SV000015', '2024-05-08', 14, 'Md Saiful islam.', 'SV', 9500.00, 'Cr', NULL, 'Invoice:INV000015, Name:RO-105, Qty:1.00 X 11500.00\n', NULL, NULL, NULL, '2024-05-08', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:33:39', '2024-10-01 16:33:39'),
(251, '01', 'CHA000015', 'INV000015', '01SV000015', '2024-05-08', 125, 'Cash', 'SV', 9500.00, 'Cr', 'Cash', 'Invoice:INV000015, Cash Received From: Md Saiful islam., Through Cash Paid Amount:9,500.00 TK\n', NULL, NULL, NULL, '2024-05-08', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:33:39', '2024-10-01 16:33:39'),
(252, '01', 'CHA000015', 'INV000015', '01SV000015', '2024-05-08', 11, 'Md Saiful islam.', 'SV', 9500.00, 'Dr', 'Cash', 'Invoice:INV000015, Cash Received From: Md Saiful islam., Through Cash Paid Amount:9,500.00 TK\n', NULL, NULL, NULL, '2024-05-08', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:33:39', '2024-10-01 16:33:39'),
(253, '01', 'CHA000016', 'INV000016', '01SV000016', '2024-05-09', 126, 'Sales Account', 'SV', 9700.00, 'Dr', NULL, 'Invoice:INV000016, Name:RO-105, Qty:1.00 X 11500.00\n\nName:6mm Pipe., Qty:20.00 X 10.00\n', NULL, NULL, NULL, '2024-05-09', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:35:15', '2024-10-01 16:35:15'),
(254, '01', 'CHA000016', 'INV000016', '01SV000016', '2024-05-09', 14, 'Mr Habibur', 'SV', 9700.00, 'Cr', NULL, 'Invoice:INV000016, Name:RO-105, Qty:1.00 X 11500.00\n\nName:6mm Pipe., Qty:20.00 X 10.00\n', NULL, NULL, NULL, '2024-05-09', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:35:15', '2024-10-01 16:35:15'),
(255, '01', 'CHA000016', 'INV000016', '01SV000016', '2024-05-09', 126, 'Cash', 'SV', 9700.00, 'Cr', 'Cash', 'Invoice:INV000016, Cash Received From: Mr Habibur, Through Cash Paid Amount:9,700.00 TK\n', NULL, NULL, NULL, '2024-05-09', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:35:15', '2024-10-01 16:35:15'),
(256, '01', 'CHA000016', 'INV000016', '01SV000016', '2024-05-09', 11, 'Mr Habibur', 'SV', 9700.00, 'Dr', 'Cash', 'Invoice:INV000016, Cash Received From: Mr Habibur, Through Cash Paid Amount:9,700.00 TK\n', NULL, NULL, NULL, '2024-05-09', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:35:15', '2024-10-01 16:35:15'),
(257, '01', 'CHA000017', 'INV000017', '01SV000017', '2024-05-12', 120, 'Sales Account', 'SV', 9150.00, 'Dr', NULL, 'Invoice:INV000017, Name:RO-105, Qty:1.00 X 11500.00\n', NULL, NULL, NULL, '2024-05-12', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:36:53', '2024-10-01 16:36:53'),
(258, '01', 'CHA000017', 'INV000017', '01SV000017', '2024-05-12', 14, 'Md Tanvir.', 'SV', 9150.00, 'Cr', NULL, 'Invoice:INV000017, Name:RO-105, Qty:1.00 X 11500.00\n', NULL, NULL, NULL, '2024-05-12', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:36:53', '2024-10-01 16:36:53'),
(259, '01', 'CHA000017', 'INV000017', '01SV000017', '2024-05-12', 120, 'Cash', 'SV', 9150.00, 'Cr', 'Cash', 'Invoice:INV000017, Cash Received From: Md Tanvir., Through Cash Paid Amount:9,150.00 TK\n', NULL, NULL, NULL, '2024-05-12', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:36:53', '2024-10-01 16:36:53'),
(260, '01', 'CHA000017', 'INV000017', '01SV000017', '2024-05-12', 11, 'Md Tanvir.', 'SV', 9150.00, 'Dr', 'Cash', 'Invoice:INV000017, Cash Received From: Md Tanvir., Through Cash Paid Amount:9,150.00 TK\n', NULL, NULL, NULL, '2024-05-12', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:36:53', '2024-10-01 16:36:53'),
(261, '01', 'CHA000018', 'INV000018', '01SV000018', '2024-05-13', 128, 'Sales Account', 'SV', 9500.00, 'Dr', NULL, 'Invoice:INV000018, Name:RO-105, Qty:1.00 X 11500.00\n', NULL, NULL, NULL, '2024-05-13', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:38:26', '2024-10-01 16:38:26'),
(262, '01', 'CHA000018', 'INV000018', '01SV000018', '2024-05-13', 14, 'Md Ziaul Haque(Zia Sir)', 'SV', 9500.00, 'Cr', NULL, 'Invoice:INV000018, Name:RO-105, Qty:1.00 X 11500.00\n', NULL, NULL, NULL, '2024-05-13', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:38:26', '2024-10-01 16:38:26'),
(263, '01', 'CHA000018', 'INV000018', '01SV000018', '2024-05-13', 128, 'Cash', 'SV', 9500.00, 'Cr', 'Cash', 'Invoice:INV000018, Cash Received From: Md Ziaul Haque(Zia Sir), Through Cash Paid Amount:9,500.00 TK\n', NULL, NULL, NULL, '2024-05-13', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:38:26', '2024-10-01 16:38:26'),
(264, '01', 'CHA000018', 'INV000018', '01SV000018', '2024-05-13', 11, 'Md Ziaul Haque(Zia Sir)', 'SV', 9500.00, 'Dr', 'Cash', 'Invoice:INV000018, Cash Received From: Md Ziaul Haque(Zia Sir), Through Cash Paid Amount:9,500.00 TK\n', NULL, NULL, NULL, '2024-05-13', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:38:26', '2024-10-01 16:38:26'),
(265, '01', 'CHA000019', 'INV000019', '01SV000019', '2024-05-16', 129, 'Sales Account', 'SV', 500.00, 'Dr', NULL, 'Invoice:INV000019, Name:10 inch pp filter, Qty:1.00 X 200.00\n\nName:Pay service, Qty:1.00 X 400.00\n', NULL, NULL, NULL, '2024-05-16', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:39:34', '2024-10-01 16:39:34'),
(266, '01', 'CHA000019', 'INV000019', '01SV000019', '2024-05-16', 14, 'Shahanaz Bristy', 'SV', 500.00, 'Cr', NULL, 'Invoice:INV000019, Name:10 inch pp filter, Qty:1.00 X 200.00\n\nName:Pay service, Qty:1.00 X 400.00\n', NULL, NULL, NULL, '2024-05-16', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:39:34', '2024-10-01 16:39:34'),
(267, '01', 'CHA000019', 'INV000019', '01SV000019', '2024-05-16', 129, 'Cash', 'SV', 500.00, 'Cr', 'Cash', 'Invoice:INV000019, Cash Received From: Shahanaz Bristy, Through Cash Paid Amount:500.00 TK\n', NULL, NULL, NULL, '2024-05-16', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:39:34', '2024-10-01 16:39:34'),
(268, '01', 'CHA000019', 'INV000019', '01SV000019', '2024-05-16', 11, 'Shahanaz Bristy', 'SV', 500.00, 'Dr', 'Cash', 'Invoice:INV000019, Cash Received From: Shahanaz Bristy, Through Cash Paid Amount:500.00 TK\n', NULL, NULL, NULL, '2024-05-16', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:39:34', '2024-10-01 16:39:34'),
(269, '01', 'CHA000020', 'INV000020', '01SV000020', '2024-05-20', 130, 'Sales Account', 'SV', 9150.00, 'Dr', NULL, 'Invoice:INV000020, Name:RO-105, Qty:1.00 X 11500.00\n\nName:6mm Pipe., Qty:15.00 X 10.00\n', NULL, NULL, NULL, '2024-05-20', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:41:42', '2024-10-01 16:41:42'),
(270, '01', 'CHA000020', 'INV000020', '01SV000020', '2024-05-20', 14, 'Mr Emon', 'SV', 9150.00, 'Cr', NULL, 'Invoice:INV000020, Name:RO-105, Qty:1.00 X 11500.00\n\nName:6mm Pipe., Qty:15.00 X 10.00\n', NULL, NULL, NULL, '2024-05-20', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:41:42', '2024-10-01 16:41:42'),
(271, '01', 'CHA000020', 'INV000020', '01SV000020', '2024-05-20', 130, 'Cash', 'SV', 9150.00, 'Cr', 'Cash', 'Invoice:INV000020, Cash Received From: Mr Emon, Through Cash Paid Amount:9,150.00 TK\n', NULL, NULL, NULL, '2024-05-20', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:41:42', '2024-10-01 16:41:42'),
(272, '01', 'CHA000020', 'INV000020', '01SV000020', '2024-05-20', 11, 'Mr Emon', 'SV', 9150.00, 'Dr', 'Cash', 'Invoice:INV000020, Cash Received From: Mr Emon, Through Cash Paid Amount:9,150.00 TK\n', NULL, NULL, NULL, '2024-05-20', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:41:42', '2024-10-01 16:41:42'),
(273, '01', 'CHA000022', 'INV000022', '01SV000022', '2024-05-15', 142, 'Sales Account', 'SV', 4940.00, 'Dr', NULL, 'Invoice:INV000022, Name:20 Inch PP Filter., Qty:1.00 X 240.00\n\nName:20 Inch CTO, Qty:1.00 X 350.00\n\nName:20 Inch GAC., Qty:1.00 X 350.00\n\nName:75 GPD Membrane, Qty:2.00 X 1850.00\n\nName:Pay service, Qty:1.00 X 300.00\n', NULL, NULL, NULL, '2024-05-15', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:51:45', '2024-10-01 16:51:45'),
(274, '01', 'CHA000022', 'INV000022', '01SV000022', '2024-05-15', 14, 'Sonali Paper and Board Mills.', 'SV', 4940.00, 'Cr', NULL, 'Invoice:INV000022, Name:20 Inch PP Filter., Qty:1.00 X 240.00\n\nName:20 Inch CTO, Qty:1.00 X 350.00\n\nName:20 Inch GAC., Qty:1.00 X 350.00\n\nName:75 GPD Membrane, Qty:2.00 X 1850.00\n\nName:Pay service, Qty:1.00 X 300.00\n', NULL, NULL, NULL, '2024-05-15', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:51:45', '2024-10-01 16:51:45'),
(275, '01', 'CHA000022', 'INV000022', '01SV000022', '2024-05-15', 142, 'Cash', 'SV', 4940.00, 'Cr', 'Cash', 'Invoice:INV000022, Cash Received From: Sonali Paper and Board Mills., Through Cash Paid Amount:4,940.00 TK\n', NULL, NULL, NULL, '2024-05-15', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:51:45', '2024-10-01 16:51:45'),
(276, '01', 'CHA000022', 'INV000022', '01SV000022', '2024-05-15', 11, 'Sonali Paper and Board Mills.', 'SV', 4940.00, 'Dr', 'Cash', 'Invoice:INV000022, Cash Received From: Sonali Paper and Board Mills., Through Cash Paid Amount:4,940.00 TK\n', NULL, NULL, NULL, '2024-05-15', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:51:45', '2024-10-01 16:51:45'),
(277, '01', 'CHA000021', 'INV000021', '01SV000021', '2024-05-16', 142, 'Sales Account', 'SV', 920.00, 'Dr', NULL, 'Invoice:INV000021, Name:10 inch pp filter, Qty:1.00 X 120.00\n\nName:10 Inch CTO Filter, Qty:1.00 X 250.00\n\nName:10 Inch GAC Filter, Qty:1.00 X 250.00\n\nName:Pay service, Qty:1.00 X 300.00\n', NULL, NULL, NULL, '2024-05-16', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:52:41', '2024-10-01 16:52:41'),
(278, '01', 'CHA000021', 'INV000021', '01SV000021', '2024-05-16', 14, 'Sonali Paper and Board Mills.', 'SV', 920.00, 'Cr', NULL, 'Invoice:INV000021, Name:10 inch pp filter, Qty:1.00 X 120.00\n\nName:10 Inch CTO Filter, Qty:1.00 X 250.00\n\nName:10 Inch GAC Filter, Qty:1.00 X 250.00\n\nName:Pay service, Qty:1.00 X 300.00\n', NULL, NULL, NULL, '2024-05-16', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:52:41', '2024-10-01 16:52:41'),
(279, '01', 'CHA000021', 'INV000021', '01SV000021', '2024-05-16', 142, 'Cash', 'SV', 920.00, 'Cr', 'Cash', 'Invoice:INV000021, Cash Received From: Sonali Paper and Board Mills., Through Cash Paid Amount:920.00 TK\n', NULL, NULL, NULL, '2024-05-16', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:52:41', '2024-10-01 16:52:41'),
(280, '01', 'CHA000021', 'INV000021', '01SV000021', '2024-05-16', 11, 'Sonali Paper and Board Mills.', 'SV', 920.00, 'Dr', 'Cash', 'Invoice:INV000021, Cash Received From: Sonali Paper and Board Mills., Through Cash Paid Amount:920.00 TK\n', NULL, NULL, NULL, '2024-05-16', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:52:41', '2024-10-01 16:52:41'),
(281, '01', 'CHA000023', 'INV000023', '01SV000023', '2024-05-30', 131, 'Sales Account', 'SV', 920.00, 'Dr', NULL, 'Invoice:INV000023, Name:10 inch pp filter, Qty:1.00 X 120.00\n\nName:10 Inch GAC Filter, Qty:1.00 X 250.00\n\nName:10 Inch CTO Filter, Qty:1.00 X 250.00\n\nName:Pay service, Qty:1.00 X 300.00\n', NULL, NULL, NULL, '2024-05-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:58:10', '2024-10-01 16:58:10'),
(282, '01', 'CHA000023', 'INV000023', '01SV000023', '2024-05-30', 14, 'Joy', 'SV', 920.00, 'Cr', NULL, 'Invoice:INV000023, Name:10 inch pp filter, Qty:1.00 X 120.00\n\nName:10 Inch GAC Filter, Qty:1.00 X 250.00\n\nName:10 Inch CTO Filter, Qty:1.00 X 250.00\n\nName:Pay service, Qty:1.00 X 300.00\n', NULL, NULL, NULL, '2024-05-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:58:10', '2024-10-01 16:58:10'),
(283, '01', 'CHA000023', 'INV000023', '01SV000023', '2024-05-30', 131, 'Cash', 'SV', 920.00, 'Cr', 'Cash', 'Invoice:INV000023, Cash Received From: Joy, Through Cash Paid Amount:920.00 TK\n', NULL, NULL, NULL, '2024-05-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:58:10', '2024-10-01 16:58:10'),
(284, '01', 'CHA000023', 'INV000023', '01SV000023', '2024-05-30', 11, 'Joy', 'SV', 920.00, 'Dr', 'Cash', 'Invoice:INV000023, Cash Received From: Joy, Through Cash Paid Amount:920.00 TK\n', NULL, NULL, NULL, '2024-05-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:58:10', '2024-10-01 16:58:10'),
(285, '01', 'CHA000024', 'INV000024', '01SV000024', '2024-05-30', 131, 'Sales Account', 'SV', 100.00, 'Dr', NULL, 'Invoice:INV000024, Name:Housing Wrench., Qty:1.00 X 100.00\n', NULL, NULL, NULL, '2024-05-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:58:44', '2024-10-01 16:58:44'),
(286, '01', 'CHA000024', 'INV000024', '01SV000024', '2024-05-30', 14, 'Joy', 'SV', 100.00, 'Cr', NULL, 'Invoice:INV000024, Name:Housing Wrench., Qty:1.00 X 100.00\n', NULL, NULL, NULL, '2024-05-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:58:44', '2024-10-01 16:58:44'),
(287, '01', 'CHA000024', 'INV000024', '01SV000024', '2024-05-30', 131, 'Cash', 'SV', 100.00, 'Cr', 'Cash', 'Invoice:INV000024, Cash Received From: Joy, Through Cash Paid Amount:100.00 TK\n', NULL, NULL, NULL, '2024-05-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:58:44', '2024-10-01 16:58:44'),
(288, '01', 'CHA000024', 'INV000024', '01SV000024', '2024-05-30', 11, 'Joy', 'SV', 100.00, 'Dr', 'Cash', 'Invoice:INV000024, Cash Received From: Joy, Through Cash Paid Amount:100.00 TK\n', NULL, NULL, NULL, '2024-05-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 16:58:44', '2024-10-01 16:58:44'),
(289, '01', 'CHA000025', 'INV000025', '01SV000025', '2024-06-01', 132, 'Sales Account', 'SV', 10000.00, 'Dr', NULL, 'Invoice:INV000025, Name:RO-105, Qty:1.00 X 11500.00\n\nName:Inline Slim Mineral Filter Heron, Qty:1.00 X 500.00\n', NULL, NULL, NULL, '2024-06-01', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:02:14', '2024-10-01 17:02:14'),
(290, '01', 'CHA000025', 'INV000025', '01SV000025', '2024-06-01', 14, 'Mr Soriful Islam', 'SV', 10000.00, 'Cr', NULL, 'Invoice:INV000025, Name:RO-105, Qty:1.00 X 11500.00\n\nName:Inline Slim Mineral Filter Heron, Qty:1.00 X 500.00\n', NULL, NULL, NULL, '2024-06-01', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:02:14', '2024-10-01 17:02:14'),
(291, '01', 'CHA000025', 'INV000025', '01SV000025', '2024-06-01', 132, 'Cash', 'SV', 10000.00, 'Cr', 'Cash', 'Invoice:INV000025, Cash Received From: Mr Soriful Islam, Through Cash Paid Amount:10,000.00 TK\n', NULL, NULL, NULL, '2024-06-01', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:02:14', '2024-10-01 17:02:14'),
(292, '01', 'CHA000025', 'INV000025', '01SV000025', '2024-06-01', 11, 'Mr Soriful Islam', 'SV', 10000.00, 'Dr', 'Cash', 'Invoice:INV000025, Cash Received From: Mr Soriful Islam, Through Cash Paid Amount:10,000.00 TK\n', NULL, NULL, NULL, '2024-06-01', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:02:14', '2024-10-01 17:02:14'),
(297, '01', 'CHA000026', 'INV000026', '01SV000026', '2024-06-03', 135, 'Sales Account', 'SV', 4310.00, 'Dr', NULL, 'Invoice:INV000026, Name:10 Inch CTO Filter, Qty:1.00 X 250.00\n\nName:10 Inch GAC Filter, Qty:1.00 X 250.00\n\nName:75 GPD Membrane, Qty:1.00 X 1750.00\n\nName:Inline Slim Mineral Filter Heron, Qty:1.00 X 450.00\n\nName:6mm Pipe., Qty:12.00 X 10.00\n\nName:Taste and Odor., Qty:1.00 X 450.00\n\nName:Transport, Qty:1.00 X 300.00\n\nName:Pay service, Qty:1.00 X 500.00\n\nName:10 inch pp filter, Qty:2.00 X 120.00\n', NULL, NULL, NULL, '2024-06-03', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:14:29', '2024-10-01 17:14:29'),
(298, '01', 'CHA000026', 'INV000026', '01SV000026', '2024-06-03', 14, 'Md Hossain Ahmed', 'SV', 4310.00, 'Cr', NULL, 'Invoice:INV000026, Name:10 Inch CTO Filter, Qty:1.00 X 250.00\n\nName:10 Inch GAC Filter, Qty:1.00 X 250.00\n\nName:75 GPD Membrane, Qty:1.00 X 1750.00\n\nName:Inline Slim Mineral Filter Heron, Qty:1.00 X 450.00\n\nName:6mm Pipe., Qty:12.00 X 10.00\n\nName:Taste and Odor., Qty:1.00 X 450.00\n\nName:Transport, Qty:1.00 X 300.00\n\nName:Pay service, Qty:1.00 X 500.00\n\nName:10 inch pp filter, Qty:2.00 X 120.00\n', NULL, NULL, NULL, '2024-06-03', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:14:29', '2024-10-01 17:14:29'),
(299, '01', 'CHA000026', 'INV000026', '01SV000026', '2024-06-03', 135, 'Cash', 'SV', 4310.00, 'Cr', 'Cash', 'Invoice:INV000026, Cash Received From: Md Hossain Ahmed, Through Cash Paid Amount:4,310.00 TK\n', NULL, NULL, NULL, '2024-06-03', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:14:29', '2024-10-01 17:14:29'),
(300, '01', 'CHA000026', 'INV000026', '01SV000026', '2024-06-03', 11, 'Md Hossain Ahmed', 'SV', 4310.00, 'Dr', 'Cash', 'Invoice:INV000026, Cash Received From: Md Hossain Ahmed, Through Cash Paid Amount:4,310.00 TK\n', NULL, NULL, NULL, '2024-06-03', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:14:29', '2024-10-01 17:14:29'),
(301, '01', 'CHA000027', 'INV000027', '01SV000027', '2024-06-04', 136, 'Sales Account', 'SV', 1350.00, 'Dr', NULL, 'Invoice:INV000027, Name:Adapter (Input 100-220V, AC-0.6Amp, Output-24V DC-1.5Amp.), Qty:1.00 X 550.00\n\nName:Pay service, Qty:1.00 X 600.00\n\nName:Transport, Qty:1.00 X 200.00\n', NULL, NULL, NULL, '2024-06-04', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:15:54', '2024-10-01 17:15:54'),
(302, '01', 'CHA000027', 'INV000027', '01SV000027', '2024-06-04', 14, 'Ms Najnin.', 'SV', 1350.00, 'Cr', NULL, 'Invoice:INV000027, Name:Adapter (Input 100-220V, AC-0.6Amp, Output-24V DC-1.5Amp.), Qty:1.00 X 550.00\n\nName:Pay service, Qty:1.00 X 600.00\n\nName:Transport, Qty:1.00 X 200.00\n', NULL, NULL, NULL, '2024-06-04', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:15:54', '2024-10-01 17:15:54'),
(303, '01', 'CHA000027', 'INV000027', '01SV000027', '2024-06-04', 136, 'Cash', 'SV', 1350.00, 'Cr', 'Cash', 'Invoice:INV000027, Cash Received From: Ms Najnin., Through Cash Paid Amount:1,350.00 TK\n', NULL, NULL, NULL, '2024-06-04', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:15:54', '2024-10-01 17:15:54'),
(304, '01', 'CHA000027', 'INV000027', '01SV000027', '2024-06-04', 11, 'Ms Najnin.', 'SV', 1350.00, 'Dr', 'Cash', 'Invoice:INV000027, Cash Received From: Ms Najnin., Through Cash Paid Amount:1,350.00 TK\n', NULL, NULL, NULL, '2024-06-04', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:15:54', '2024-10-01 17:15:54'),
(305, '01', 'CHA000028', 'INV000028', '01SV000028', '2024-06-04', 135, 'Sales Account', 'SV', 550.00, 'Dr', NULL, 'Invoice:INV000028, Name:Membrane Housing., Qty:1.00 X 550.00\n', NULL, NULL, NULL, '2024-06-04', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:16:59', '2024-10-01 17:16:59'),
(306, '01', 'CHA000028', 'INV000028', '01SV000028', '2024-06-04', 14, 'Md Hossain Ahmed', 'SV', 550.00, 'Cr', NULL, 'Invoice:INV000028, Name:Membrane Housing., Qty:1.00 X 550.00\n', NULL, NULL, NULL, '2024-06-04', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:16:59', '2024-10-01 17:16:59'),
(307, '01', 'CHA000028', 'INV000028', '01SV000028', '2024-06-04', 135, 'Cash', 'SV', 550.00, 'Cr', 'Cash', 'Invoice:INV000028, Cash Received From: Md Hossain Ahmed, Through Cash Paid Amount:550.00 TK\n', NULL, NULL, NULL, '2024-06-04', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:16:59', '2024-10-01 17:16:59'),
(308, '01', 'CHA000028', 'INV000028', '01SV000028', '2024-06-04', 11, 'Md Hossain Ahmed', 'SV', 550.00, 'Dr', 'Cash', 'Invoice:INV000028, Cash Received From: Md Hossain Ahmed, Through Cash Paid Amount:550.00 TK\n', NULL, NULL, NULL, '2024-06-04', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:16:59', '2024-10-01 17:16:59'),
(309, '01', 'CHA000029', 'INV000029', '01SV000029', '2024-06-13', 133, 'Sales Account', 'SV', 19000.00, 'Dr', NULL, 'Invoice:INV000029, Name:RO-105, Qty:2.00 X 9500.00\n', NULL, NULL, NULL, '2024-06-13', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:23:55', '2024-10-01 17:23:55'),
(310, '01', 'CHA000029', 'INV000029', '01SV000029', '2024-06-13', 14, 'Sohel (Zia sir)', 'SV', 19000.00, 'Cr', NULL, 'Invoice:INV000029, Name:RO-105, Qty:2.00 X 9500.00\n', NULL, NULL, NULL, '2024-06-13', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:23:55', '2024-10-01 17:23:55'),
(311, '01', 'CHA000029', 'INV000029', '01SV000029', '2024-06-13', 133, 'Cash', 'SV', 19000.00, 'Cr', 'Cash', 'Invoice:INV000029, Cash Received From: Sohel (Zia sir), Through Cash Paid Amount:19,000.00 TK\n', NULL, NULL, NULL, '2024-06-13', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:23:55', '2024-10-01 17:23:55'),
(312, '01', 'CHA000029', 'INV000029', '01SV000029', '2024-06-13', 11, 'Sohel (Zia sir)', 'SV', 19000.00, 'Dr', 'Cash', 'Invoice:INV000029, Cash Received From: Sohel (Zia sir), Through Cash Paid Amount:19,000.00 TK\n', NULL, NULL, NULL, '2024-06-13', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:23:55', '2024-10-01 17:23:55'),
(313, '01', 'CHA000030', 'INV000030', '01SV000030', '2024-06-08', 143, 'Sales Account', 'SV', 280.00, 'Dr', NULL, 'Invoice:INV000030, Name:10 inch pp filter, Qty:1.00 X 120.00\n\nName:Transport, Qty:1.00 X 80.00\n\nName:Pay service, Qty:1.00 X 80.00\n', NULL, NULL, NULL, '2024-06-08', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:24:59', '2024-10-01 17:24:59'),
(314, '01', 'CHA000030', 'INV000030', '01SV000030', '2024-06-08', 14, 'Md Alomgir Sir.', 'SV', 280.00, 'Cr', NULL, 'Invoice:INV000030, Name:10 inch pp filter, Qty:1.00 X 120.00\n\nName:Transport, Qty:1.00 X 80.00\n\nName:Pay service, Qty:1.00 X 80.00\n', NULL, NULL, NULL, '2024-06-08', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:24:59', '2024-10-01 17:24:59'),
(315, '01', 'CHA000030', 'INV000030', '01SV000030', '2024-06-08', 143, 'Cash', 'SV', 280.00, 'Cr', 'Cash', 'Invoice:INV000030, Cash Received From: Md Alomgir Sir., Through Cash Paid Amount:280.00 TK\n', NULL, NULL, NULL, '2024-06-08', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:24:59', '2024-10-01 17:24:59'),
(316, '01', 'CHA000030', 'INV000030', '01SV000030', '2024-06-08', 11, 'Md Alomgir Sir.', 'SV', 280.00, 'Dr', 'Cash', 'Invoice:INV000030, Cash Received From: Md Alomgir Sir., Through Cash Paid Amount:280.00 TK\n', NULL, NULL, NULL, '2024-06-08', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:24:59', '2024-10-01 17:24:59'),
(317, '01', 'CHA000033', 'INV000033', '01SV000033', '2024-06-08', 144, 'Sales Account', 'SV', 400.00, 'Dr', NULL, 'Invoice:INV000033, Name:10 inch pp filter, Qty:2.00 X 120.00\n\nName:Pay service, Qty:1.00 X 160.00\n', NULL, NULL, NULL, '2024-06-08', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:26:39', '2024-10-01 17:26:39'),
(318, '01', 'CHA000033', 'INV000033', '01SV000033', '2024-06-08', 14, 'Mr Monu.', 'SV', 400.00, 'Cr', NULL, 'Invoice:INV000033, Name:10 inch pp filter, Qty:2.00 X 120.00\n\nName:Pay service, Qty:1.00 X 160.00\n', NULL, NULL, NULL, '2024-06-08', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:26:39', '2024-10-01 17:26:39'),
(319, '01', 'CHA000033', 'INV000033', '01SV000033', '2024-06-08', 144, 'Cash', 'SV', 400.00, 'Cr', 'Cash', 'Invoice:INV000033, Cash Received From: Mr Monu., Through Cash Paid Amount:400.00 TK\n', NULL, NULL, NULL, '2024-06-08', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:26:39', '2024-10-01 17:26:39'),
(320, '01', 'CHA000033', 'INV000033', '01SV000033', '2024-06-08', 11, 'Mr Monu.', 'SV', 400.00, 'Dr', 'Cash', 'Invoice:INV000033, Cash Received From: Mr Monu., Through Cash Paid Amount:400.00 TK\n', NULL, NULL, NULL, '2024-06-08', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:26:39', '2024-10-01 17:26:39'),
(321, '01', 'CHA000031', 'INV000031', '01SV000031', '2024-06-09', 142, 'Sales Account', 'SV', 2150.00, 'Dr', NULL, 'Invoice:INV000031, Name:75 GPD Membrane, Qty:1.00 X 1850.00\n\nName:Pay service, Qty:1.00 X 300.00\n', NULL, NULL, NULL, '2024-06-09', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:28:48', '2024-10-01 17:28:48'),
(322, '01', 'CHA000031', 'INV000031', '01SV000031', '2024-06-09', 14, 'Sonali Paper and Board Mills.', 'SV', 2150.00, 'Cr', NULL, 'Invoice:INV000031, Name:75 GPD Membrane, Qty:1.00 X 1850.00\n\nName:Pay service, Qty:1.00 X 300.00\n', NULL, NULL, NULL, '2024-06-09', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:28:48', '2024-10-01 17:28:48'),
(323, '01', 'CHA000031', 'INV000031', '01SV000031', '2024-06-09', 142, 'Cash', 'SV', 2150.00, 'Cr', 'Cash', 'Invoice:INV000031, Cash Received From: Sonali Paper and Board Mills., Through Cash Paid Amount:2,150.00 TK\n', NULL, NULL, NULL, '2024-06-09', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:28:48', '2024-10-01 17:28:48'),
(324, '01', 'CHA000031', 'INV000031', '01SV000031', '2024-06-09', 11, 'Sonali Paper and Board Mills.', 'SV', 2150.00, 'Dr', 'Cash', 'Invoice:INV000031, Cash Received From: Sonali Paper and Board Mills., Through Cash Paid Amount:2,150.00 TK\n', NULL, NULL, NULL, '2024-06-09', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:28:48', '2024-10-01 17:28:48'),
(325, '01', 'CHA000032', 'INV000032', '01SV000032', '2024-06-29', 137, 'Sales Account', 'SV', 9650.00, 'Dr', NULL, 'Invoice:INV000032, Name:RO-105, Qty:1.00 X 11500.00\n\nName:6mm Pipe., Qty:15.00 X 10.00\n', NULL, NULL, NULL, '2024-06-29', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:30:22', '2024-10-01 17:30:22'),
(326, '01', 'CHA000032', 'INV000032', '01SV000032', '2024-06-29', 14, 'Shakwat Rahim  Khan.', 'SV', 9650.00, 'Cr', NULL, 'Invoice:INV000032, Name:RO-105, Qty:1.00 X 11500.00\n\nName:6mm Pipe., Qty:15.00 X 10.00\n', NULL, NULL, NULL, '2024-06-29', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:30:22', '2024-10-01 17:30:22'),
(327, '01', 'CHA000032', 'INV000032', '01SV000032', '2024-06-29', 137, 'Cash', 'SV', 9650.00, 'Cr', 'Cash', 'Invoice:INV000032, Cash Received From: Shakwat Rahim  Khan., Through Cash Paid Amount:9,650.00 TK\n', NULL, NULL, NULL, '2024-06-29', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:30:22', '2024-10-01 17:30:22'),
(328, '01', 'CHA000032', 'INV000032', '01SV000032', '2024-06-29', 11, 'Shakwat Rahim  Khan.', 'SV', 9650.00, 'Dr', 'Cash', 'Invoice:INV000032, Cash Received From: Shakwat Rahim  Khan., Through Cash Paid Amount:9,650.00 TK\n', NULL, NULL, NULL, '2024-06-29', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:30:22', '2024-10-01 17:30:22'),
(329, '01', 'CHA000034', 'INV000034', '01SV000034', '2024-06-27', 138, 'Sales Account', 'SV', 9650.00, 'Dr', NULL, 'Invoice:INV000034, Name:RO-105, Qty:1.00 X 10500.00\n\nName:6mm Pipe., Qty:15.00 X 10.00\n', NULL, NULL, NULL, '2024-06-27', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:32:04', '2024-10-01 17:32:04'),
(330, '01', 'CHA000034', 'INV000034', '01SV000034', '2024-06-27', 14, 'Mr Robiul.', 'SV', 9650.00, 'Cr', NULL, 'Invoice:INV000034, Name:RO-105, Qty:1.00 X 10500.00\n\nName:6mm Pipe., Qty:15.00 X 10.00\n', NULL, NULL, NULL, '2024-06-27', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:32:04', '2024-10-01 17:32:04'),
(331, '01', 'CHA000034', 'INV000034', '01SV000034', '2024-06-27', 138, 'Cash', 'SV', 9650.00, 'Cr', 'Cash', 'Invoice:INV000034, Cash Received From: Mr Robiul., Through Cash Paid Amount:9,650.00 TK\n', NULL, NULL, NULL, '2024-06-27', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:32:04', '2024-10-01 17:32:04'),
(332, '01', 'CHA000034', 'INV000034', '01SV000034', '2024-06-27', 11, 'Mr Robiul.', 'SV', 9650.00, 'Dr', 'Cash', 'Invoice:INV000034, Cash Received From: Mr Robiul., Through Cash Paid Amount:9,650.00 TK\n', NULL, NULL, NULL, '2024-06-27', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:32:04', '2024-10-01 17:32:04'),
(333, '01', 'CHA000035', 'INV000035', '01SV000035', '2024-06-30', 131, 'Sales Account', 'SV', 120.00, 'Dr', NULL, 'Invoice:INV000035, Name:10 inch pp filter, Qty:1.00 X 120.00\n', NULL, NULL, NULL, '2024-06-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:33:44', '2024-10-01 17:33:44'),
(334, '01', 'CHA000035', 'INV000035', '01SV000035', '2024-06-30', 14, 'Joy', 'SV', 120.00, 'Cr', NULL, 'Invoice:INV000035, Name:10 inch pp filter, Qty:1.00 X 120.00\n', NULL, NULL, NULL, '2024-06-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:33:44', '2024-10-01 17:33:44'),
(335, '01', 'CHA000035', 'INV000035', '01SV000035', '2024-06-30', 131, 'Cash', 'SV', 120.00, 'Cr', 'Cash', 'Invoice:INV000035, Cash Received From: Joy, Through Cash Paid Amount:120.00 TK\n', NULL, NULL, NULL, '2024-06-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:33:44', '2024-10-01 17:33:44'),
(336, '01', 'CHA000035', 'INV000035', '01SV000035', '2024-06-30', 11, 'Joy', 'SV', 120.00, 'Dr', 'Cash', 'Invoice:INV000035, Cash Received From: Joy, Through Cash Paid Amount:120.00 TK\n', NULL, NULL, NULL, '2024-06-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:33:44', '2024-10-01 17:33:44'),
(337, '01', 'CHA000059', 'INV000059', '01SV000059', '2024-10-01', 139, 'Sales Account', 'SV', 1280.00, 'Dr', NULL, 'Invoice:INV000059, Name:10 inch pp filter Qty:4 X 125\n\nName:10 Inch GAC Filter Qty:1 X 240\n\nName:10 Inch CTO Filter Qty:1 X 240\n\nName:Transport Qty:1 X 300\n', NULL, NULL, NULL, '2024-06-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:40:06', '2024-10-01 17:40:06'),
(338, '01', 'CHA000059', 'INV000059', '01SV000059', '2024-10-01', 14, 'Abir', 'SV', 1280.00, 'Cr', NULL, 'Invoice:INV000059, Name:10 inch pp filter Qty:4 X 125\n\nName:10 Inch GAC Filter Qty:1 X 240\n\nName:10 Inch CTO Filter Qty:1 X 240\n\nName:Transport Qty:1 X 300\n', NULL, NULL, NULL, '2024-06-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:40:06', '2024-10-01 17:40:06'),
(339, '01', 'CHA000059', 'INV000059', '01SV000059', '2024-10-01', 139, 'Cash', 'SV', 1280.00, 'Cr', 'Cash', 'Invoice:INV000059, Cash Received From Abir, Cash Payment Amount:1,280.00 TK\n', '0', NULL, NULL, '2024-06-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:40:06', '2024-10-01 17:40:06'),
(340, '01', 'CHA000059', 'INV000059', '01SV000059', '2024-10-01', 11, 'Abir', 'SV', 1280.00, 'Dr', 'Cash', 'Invoice:INV000059, Cash Received From Abir, Cash Payment Amount:1,280.00 TK\n', '0', NULL, NULL, '2024-06-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:40:06', '2024-10-01 17:40:06'),
(341, '01', 'CHA000036', 'INV000036', '01SV000036', '2024-07-01', 140, 'Sales Account', 'SV', 9650.00, 'Dr', NULL, 'Invoice:INV000036, Name:RO-105, Qty:1.00 X 11500.00\n\nName:6mm Pipe., Qty:15.00 X 10.00\n', NULL, NULL, NULL, '2024-07-01', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:55:21', '2024-10-01 17:55:21'),
(342, '01', 'CHA000036', 'INV000036', '01SV000036', '2024-07-01', 14, 'Mr Adnan', 'SV', 9650.00, 'Cr', NULL, 'Invoice:INV000036, Name:RO-105, Qty:1.00 X 11500.00\n\nName:6mm Pipe., Qty:15.00 X 10.00\n', NULL, NULL, NULL, '2024-07-01', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:55:21', '2024-10-01 17:55:21'),
(343, '01', 'CHA000036', 'INV000036', '01SV000036', '2024-07-01', 140, 'Cash', 'SV', 9650.00, 'Cr', 'Cash', 'Invoice:INV000036, Cash Received From: Mr Adnan, Through Cash Paid Amount:9,650.00 TK\n', NULL, NULL, NULL, '2024-07-01', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:55:21', '2024-10-01 17:55:21'),
(344, '01', 'CHA000036', 'INV000036', '01SV000036', '2024-07-01', 11, 'Mr Adnan', 'SV', 9650.00, 'Dr', 'Cash', 'Invoice:INV000036, Cash Received From: Mr Adnan, Through Cash Paid Amount:9,650.00 TK\n', NULL, NULL, NULL, '2024-07-01', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:55:21', '2024-10-01 17:55:21'),
(345, '01', 'CHA000037', 'INV000037', '01SV000037', '2024-07-04', 127, 'Sales Account', 'SV', 120.00, 'Dr', NULL, 'Invoice:INV000037, Name:10 inch pp filter, Qty:1.00 X 120.00\n', NULL, NULL, NULL, '2024-07-04', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:56:29', '2024-10-01 17:56:29'),
(346, '01', 'CHA000037', 'INV000037', '01SV000037', '2024-07-04', 14, 'Mr Tanvir (  Rubel Acc)', 'SV', 120.00, 'Cr', NULL, 'Invoice:INV000037, Name:10 inch pp filter, Qty:1.00 X 120.00\n', NULL, NULL, NULL, '2024-07-04', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:56:29', '2024-10-01 17:56:29'),
(347, '01', 'CHA000037', 'INV000037', '01SV000037', '2024-07-04', 127, 'Cash', 'SV', 120.00, 'Cr', 'Cash', 'Invoice:INV000037, Cash Received From: Mr Tanvir (  Rubel Acc), Through Cash Paid Amount:120.00 TK\n', NULL, NULL, NULL, '2024-07-04', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:56:29', '2024-10-01 17:56:29'),
(348, '01', 'CHA000037', 'INV000037', '01SV000037', '2024-07-04', 11, 'Mr Tanvir (  Rubel Acc)', 'SV', 120.00, 'Dr', 'Cash', 'Invoice:INV000037, Cash Received From: Mr Tanvir (  Rubel Acc), Through Cash Paid Amount:120.00 TK\n', NULL, NULL, NULL, '2024-07-04', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:56:29', '2024-10-01 17:56:29'),
(349, '01', 'CHA000038', 'INV000038', '01SV000038', '2024-07-08', 141, 'Sales Account', 'SV', 1220.00, 'Dr', NULL, 'Invoice:INV000038, Name:10 inch pp filter, Qty:1.00 X 120.00\n\nName:10 Inch CTO Filter, Qty:1.00 X 250.00\n\nName:10 Inch GAC Filter, Qty:1.00 X 250.00\n\nName:Pay service, Qty:1.00 X 300.00\n\nName:Transport, Qty:1.00 X 300.00\n', NULL, NULL, NULL, '2024-07-08', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:57:30', '2024-10-01 17:57:30'),
(350, '01', 'CHA000038', 'INV000038', '01SV000038', '2024-07-08', 14, 'Mr Ashraful.', 'SV', 1220.00, 'Cr', NULL, 'Invoice:INV000038, Name:10 inch pp filter, Qty:1.00 X 120.00\n\nName:10 Inch CTO Filter, Qty:1.00 X 250.00\n\nName:10 Inch GAC Filter, Qty:1.00 X 250.00\n\nName:Pay service, Qty:1.00 X 300.00\n\nName:Transport, Qty:1.00 X 300.00\n', NULL, NULL, NULL, '2024-07-08', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:57:30', '2024-10-01 17:57:30'),
(351, '01', 'CHA000038', 'INV000038', '01SV000038', '2024-07-08', 141, 'Cash', 'SV', 1220.00, 'Cr', 'Cash', 'Invoice:INV000038, Cash Received From: Mr Ashraful., Through Cash Paid Amount:1,220.00 TK\n', NULL, NULL, NULL, '2024-07-08', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:57:30', '2024-10-01 17:57:30'),
(352, '01', 'CHA000038', 'INV000038', '01SV000038', '2024-07-08', 11, 'Mr Ashraful.', 'SV', 1220.00, 'Dr', 'Cash', 'Invoice:INV000038, Cash Received From: Mr Ashraful., Through Cash Paid Amount:1,220.00 TK\n', NULL, NULL, NULL, '2024-07-08', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 17:57:30', '2024-10-01 17:57:30'),
(353, '01', 'CHA000060', 'INV000060', '01SV000060', '2024-10-01', 127, 'Sales Account', 'SV', 700.00, 'Dr', NULL, 'Invoice:INV000060, Name:Inline Slim Mineral Filter Heron Qty:1 X 700\n', NULL, NULL, NULL, '2024-07-08', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 18:03:25', '2024-10-01 18:03:25'),
(354, '01', 'CHA000060', 'INV000060', '01SV000060', '2024-10-01', 14, 'Mr Tanvir (  Rubel Acc)', 'SV', 700.00, 'Cr', NULL, 'Invoice:INV000060, Name:Inline Slim Mineral Filter Heron Qty:1 X 700\n', NULL, NULL, NULL, '2024-07-08', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 18:03:25', '2024-10-01 18:03:25'),
(355, '01', 'CHA000060', 'INV000060', '01SV000060', '2024-10-01', 127, 'Cash', 'SV', 700.00, 'Cr', 'Cash', 'Invoice:INV000060, Cash Received From Mr Tanvir (  Rubel Acc), Cash Payment Amount:700.00 TK\n', '0', NULL, NULL, '2024-07-08', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 18:03:25', '2024-10-01 18:03:25'),
(356, '01', 'CHA000060', 'INV000060', '01SV000060', '2024-10-01', 11, 'Mr Tanvir (  Rubel Acc)', 'SV', 700.00, 'Dr', 'Cash', 'Invoice:INV000060, Cash Received From Mr Tanvir (  Rubel Acc), Cash Payment Amount:700.00 TK\n', '0', NULL, NULL, '2024-07-08', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 18:03:25', '2024-10-01 18:03:25'),
(357, '01', 'CHA000039', 'INV000039', '01SV000039', '2024-07-11', 134, 'Sales Account', 'SV', 9500.00, 'Dr', NULL, 'Invoice:INV000039, Name:RO-105, Qty:1.00 X 11500.00\n', NULL, NULL, NULL, '2024-07-11', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 18:05:15', '2024-10-01 18:05:15'),
(358, '01', 'CHA000039', 'INV000039', '01SV000039', '2024-07-11', 14, 'Mrs. Pinky.', 'SV', 9500.00, 'Cr', NULL, 'Invoice:INV000039, Name:RO-105, Qty:1.00 X 11500.00\n', NULL, NULL, NULL, '2024-07-11', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 18:05:15', '2024-10-01 18:05:15'),
(359, '01', 'CHA000039', 'INV000039', '01SV000039', '2024-07-11', 134, 'Cash', 'SV', 9500.00, 'Cr', 'Cash', 'Invoice:INV000039, Cash Received From: Mrs. Pinky., Through Cash Paid Amount:9,500.00 TK\n', NULL, NULL, NULL, '2024-07-11', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 18:05:15', '2024-10-01 18:05:15'),
(360, '01', 'CHA000039', 'INV000039', '01SV000039', '2024-07-11', 11, 'Mrs. Pinky.', 'SV', 9500.00, 'Dr', 'Cash', 'Invoice:INV000039, Cash Received From: Mrs. Pinky., Through Cash Paid Amount:9,500.00 TK\n', NULL, NULL, NULL, '2024-07-11', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 18:05:15', '2024-10-01 18:05:15'),
(361, '01', 'CHA000040', 'INV000040', '01SV000040', '2024-07-13', 145, 'Sales Account', 'SV', 3750.00, 'Dr', NULL, 'Invoice:INV000040, Name:20 Inch PP Filter., Qty:3.00 X 200.00\n\nName:20 Inch CTO, Qty:1.00 X 450.00\n\nName:20 Inch GAC., Qty:1.00 X 450.00\n\nName:75 GPD Membrane, Qty:1.00 X 1750.00\n\nName:Pay service, Qty:1.00 X 500.00\n', NULL, NULL, NULL, '2024-07-13', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 18:52:28', '2024-10-01 18:52:28'),
(362, '01', 'CHA000040', 'INV000040', '01SV000040', '2024-07-13', 14, 'Sonali Paper  Mill Head Office Centeen.', 'SV', 3750.00, 'Cr', NULL, 'Invoice:INV000040, Name:20 Inch PP Filter., Qty:3.00 X 200.00\n\nName:20 Inch CTO, Qty:1.00 X 450.00\n\nName:20 Inch GAC., Qty:1.00 X 450.00\n\nName:75 GPD Membrane, Qty:1.00 X 1750.00\n\nName:Pay service, Qty:1.00 X 500.00\n', NULL, NULL, NULL, '2024-07-13', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 18:52:28', '2024-10-01 18:52:28'),
(363, '01', 'CHA000040', 'INV000040', '01SV000040', '2024-07-13', 145, 'Cash', 'SV', 3750.00, 'Cr', 'Cash', 'Invoice:INV000040, Cash Received From: Sonali Paper  Mill Head Office Centeen., Through Cash Paid Amount:3,750.00 TK\n', NULL, NULL, NULL, '2024-07-13', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 18:52:28', '2024-10-01 18:52:28'),
(364, '01', 'CHA000040', 'INV000040', '01SV000040', '2024-07-13', 11, 'Sonali Paper  Mill Head Office Centeen.', 'SV', 3750.00, 'Dr', 'Cash', 'Invoice:INV000040, Cash Received From: Sonali Paper  Mill Head Office Centeen., Through Cash Paid Amount:3,750.00 TK\n', NULL, NULL, NULL, '2024-07-13', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-01 18:52:28', '2024-10-01 18:52:28');
INSERT INTO `finance_transactions` (`id`, `company_code`, `delivery_challan_no`, `invoice_no`, `voucher_no`, `voucher_date`, `acid`, `to_acc_name`, `type`, `amount`, `balance_type`, `payment_type`, `narration`, `cheque_no`, `cheque_date`, `cheque_type`, `transaction_date`, `transaction_by`, `invoice_type`, `pending_adjustment`, `status`, `done_by`, `updated_by`, `created_at`, `updated_at`) VALUES
(413, '01', NULL, 'PUR000001', '01PV000001', '2024-08-22', 13, 'ABM engineering', 'PV', 231640.00, 'Dr', NULL, 'Invoice:PUR000001, Name:Inline BIg Sediment Filter, Qty:24.00 X 150.00,\n\nName:10 inch pp filter, Qty:50.00 X 33.00,\n\nName:10 Inch CTO Filter, Qty:25.00 X 90.00,\n\nName:10 Inch GAC Filter, Qty:25.00 X 90.00,\n\nName:Single Clamp Big, Qty:50.00 X 8.00,\n\nName:Double Clamp Big Small, Qty:50.00 X 8.00,\n\nName:RO- Male Elbow, Qty:100.00 X 8.00,\n\nName:RO Purifier Faucet SS, Qty:12.00 X 230.00,\n\nName:10 Inch Housing Wrench White, Qty:50.00 X 15.00,\n\nName:6mm Water Connector Ball Valve, Qty:24.00 X 80.00,\n\nName:Adapter (Input 100-220V, AC-0.6Amp, Output-24V DC-1.5Amp.), Qty:12.00 X 350.00,\n\nName:High Pressure Switch, Qty:25.00 X 75.00,\n\nName:Low Pressure Switch, Qty:25.00 X 75.00,\n\nName:Solenoid Valve, Qty:20.00 X 170.00,\n\nName:Flow Restrictor, Qty:24.00 X 35.00,\n\nName:Water Storage Tank, Qty:6.00 X 2500.00,\n\nName:Tank Valve, Qty:12.00 X 35.00,\n\nName:Manual Flash valve, Qty:12.00 X 50.00,\n\nName:Tee Connector, Qty:100.00 X 15.00,\n\nName:Adapter 100 GPD, Qty:12.00 X 600.00,\n\nName:Adapter 200 GPD, Qty:12.00 X 750.00,\n\nName:Water Connector SS Nipple, Qty:24.00 X 90.00,\n\nName:Inline Slim Mineral Filter Heron, Qty:24.00 X 150.00,\n\nName:Inline Slim Alkaline Filter Heron, Qty:24.00 X 170.00,\n\nName:UV Set 6 watt Heron, Qty:12.00 X 1500.00,\n\nName:Inline Big UF Filter Non Brand, Qty:12.00 X 500.00,\n\nName:RO Male Elbow, Qty:100.00 X 20.00,\n\nName:10mm Water connector Valve., Qty:12.00 X 80.00,\n\nName:Inline Big Post Carbon Filter, Qty:12.00 X 150.00,\n\nName:Float Switch Electric, Qty:6.00 X 120.00,\n\nName:RO Machine CT40, Qty:1.00 X 11000.00,\n\nName:Non RO UV 5 Stage 20 Inch Machine Heron., Qty:1.00 X 6000.00,\n\nName:RO Machine 200 GPD Heron., Qty:1.00 X 18000.00,\n\nName:RO Machine Heron Zi White., Qty:1.00 X 7000.00,\n\nName:RO Machine Heron Max (Hot,Cold,Normal)., Qty:1.00 X 12000.00,\n\nName:Auto Sensor For Water Storage Tank., Qty:12.00 X 250.00,\n\nName:O Ring for 10 Inch Housing., Qty:25.00 X 10.00,\n\nName:10mm GDL Flow Tube White Roll., Qty:1.00 X 1800.00,\n\nName:Flow Restrictor ,Type-650CC., Qty:12.00 X 50.00,\n\nName:Water Storage Tank 6 Gallon., Qty:6.00 X 2500.00,\n\nName:UF Machine 100 GPD., Qty:1.00 X 5000.00,\n\nName:Booster Pump 75 GPD., Qty:10.00 X 1400.00,\n\nName:Booster Pump 100 GPD., Qty:5.00 X 1500.00,\n\nName:10 Inch Clear Housing 1/2 GDL for iron Removal., Qty:25.00 X 480.00,\n\nName:Small American Faucet., Qty:25.00 X 450.00,\n\nName:20 Inch PP Filter., Qty:25.00 X 70.00,\n\nName:20 Inch Big PP Filter ,Dot 680gm., Qty:12.00 X 250.00,\n\nName:Tap for RO machine, Qty:6.00 X 80.00,\n', NULL, NULL, NULL, '2024-08-22', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(414, '01', NULL, 'PUR000001', '01PV000001', '2024-08-22', 112, 'Purchase Account', 'PV', 231640.00, 'Cr', NULL, 'Invoice:PUR000001, Name:Inline BIg Sediment Filter, Qty:24.00 X 150.00,\n\nName:10 inch pp filter, Qty:50.00 X 33.00,\n\nName:10 Inch CTO Filter, Qty:25.00 X 90.00,\n\nName:10 Inch GAC Filter, Qty:25.00 X 90.00,\n\nName:Single Clamp Big, Qty:50.00 X 8.00,\n\nName:Double Clamp Big Small, Qty:50.00 X 8.00,\n\nName:RO- Male Elbow, Qty:100.00 X 8.00,\n\nName:RO Purifier Faucet SS, Qty:12.00 X 230.00,\n\nName:10 Inch Housing Wrench White, Qty:50.00 X 15.00,\n\nName:6mm Water Connector Ball Valve, Qty:24.00 X 80.00,\n\nName:Adapter (Input 100-220V, AC-0.6Amp, Output-24V DC-1.5Amp.), Qty:12.00 X 350.00,\n\nName:High Pressure Switch, Qty:25.00 X 75.00,\n\nName:Low Pressure Switch, Qty:25.00 X 75.00,\n\nName:Solenoid Valve, Qty:20.00 X 170.00,\n\nName:Flow Restrictor, Qty:24.00 X 35.00,\n\nName:Water Storage Tank, Qty:6.00 X 2500.00,\n\nName:Tank Valve, Qty:12.00 X 35.00,\n\nName:Manual Flash valve, Qty:12.00 X 50.00,\n\nName:Tee Connector, Qty:100.00 X 15.00,\n\nName:Adapter 100 GPD, Qty:12.00 X 600.00,\n\nName:Adapter 200 GPD, Qty:12.00 X 750.00,\n\nName:Water Connector SS Nipple, Qty:24.00 X 90.00,\n\nName:Inline Slim Mineral Filter Heron, Qty:24.00 X 150.00,\n\nName:Inline Slim Alkaline Filter Heron, Qty:24.00 X 170.00,\n\nName:UV Set 6 watt Heron, Qty:12.00 X 1500.00,\n\nName:Inline Big UF Filter Non Brand, Qty:12.00 X 500.00,\n\nName:RO Male Elbow, Qty:100.00 X 20.00,\n\nName:10mm Water connector Valve., Qty:12.00 X 80.00,\n\nName:Inline Big Post Carbon Filter, Qty:12.00 X 150.00,\n\nName:Float Switch Electric, Qty:6.00 X 120.00,\n\nName:RO Machine CT40, Qty:1.00 X 11000.00,\n\nName:Non RO UV 5 Stage 20 Inch Machine Heron., Qty:1.00 X 6000.00,\n\nName:RO Machine 200 GPD Heron., Qty:1.00 X 18000.00,\n\nName:RO Machine Heron Zi White., Qty:1.00 X 7000.00,\n\nName:RO Machine Heron Max (Hot,Cold,Normal)., Qty:1.00 X 12000.00,\n\nName:Auto Sensor For Water Storage Tank., Qty:12.00 X 250.00,\n\nName:O Ring for 10 Inch Housing., Qty:25.00 X 10.00,\n\nName:10mm GDL Flow Tube White Roll., Qty:1.00 X 1800.00,\n\nName:Flow Restrictor ,Type-650CC., Qty:12.00 X 50.00,\n\nName:Water Storage Tank 6 Gallon., Qty:6.00 X 2500.00,\n\nName:UF Machine 100 GPD., Qty:1.00 X 5000.00,\n\nName:Booster Pump 75 GPD., Qty:10.00 X 1400.00,\n\nName:Booster Pump 100 GPD., Qty:5.00 X 1500.00,\n\nName:10 Inch Clear Housing 1/2 GDL for iron Removal., Qty:25.00 X 480.00,\n\nName:Small American Faucet., Qty:25.00 X 450.00,\n\nName:20 Inch PP Filter., Qty:25.00 X 70.00,\n\nName:20 Inch Big PP Filter ,Dot 680gm., Qty:12.00 X 250.00,\n\nName:Tap for RO machine, Qty:6.00 X 80.00,\n', NULL, NULL, NULL, '2024-08-22', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(415, '01', NULL, 'PUR000001', '01PV000001', '2024-08-22', 112, 'Cash', 'PV', 231640.00, 'Dr', 'Cash in hand', 'Invoice:PUR000001, Cash Payment To: ABM engineering, Payment Amount:2,31,640.00 TK\n', NULL, NULL, NULL, '2024-08-22', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(416, '01', NULL, 'PUR000001', '01PV000001', '2024-08-22', 11, 'ABM engineering', 'PV', 231640.00, 'Cr', 'Cash in hand', 'Invoice:PUR000001, Cash Payment To: ABM engineering, Payment Amount:2,31,640.00 TK\n', NULL, NULL, NULL, '2024-08-22', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(423, '01', 'CHA000056', 'INV000056', '01SV000056', '2024-09-12', 139, 'Sales Account', 'SV', 300.00, 'Dr', NULL, 'Invoice:INV000056, Name:Pay service, Qty:1.00 X 150.00\n\nName:Transport, Qty:1.00 X 150.00\n', NULL, NULL, NULL, '2024-09-12', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 15:09:21', '2024-10-06 15:09:21'),
(424, '01', 'CHA000056', 'INV000056', '01SV000056', '2024-09-12', 14, 'Abir', 'SV', 300.00, 'Cr', NULL, 'Invoice:INV000056, Name:Pay service, Qty:1.00 X 150.00\n\nName:Transport, Qty:1.00 X 150.00\n', NULL, NULL, NULL, '2024-09-12', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 15:09:21', '2024-10-06 15:09:21'),
(425, '01', 'CHA000056', 'INV000056', '01SV000056', '2024-09-12', 139, 'Cash', 'SV', 300.00, 'Cr', 'Cash', 'Invoice:INV000056, Cash Received From: Abir, Through Cash Paid Amount:300.00 TK\n', NULL, NULL, NULL, '2024-09-12', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 15:09:21', '2024-10-06 15:09:21'),
(426, '01', 'CHA000056', 'INV000056', '01SV000056', '2024-09-12', 11, 'Abir', 'SV', 300.00, 'Dr', 'Cash', 'Invoice:INV000056, Cash Received From: Abir, Through Cash Paid Amount:300.00 TK\n', NULL, NULL, NULL, '2024-09-12', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 15:09:21', '2024-10-06 15:09:21'),
(427, '01', 'CHA000054', 'INV000054', '01SV000054', '2024-08-24', 147, 'Sales Account', 'SV', 800.00, 'Dr', NULL, 'Invoice:INV000054, Name:Adapter (Input 100-220V, AC-0.6Amp, Output-24V DC-1.5Amp.), Qty:1.00 X 550.00\n\nName:Pay service, Qty:1.00 X 300.00\n', NULL, NULL, NULL, '2024-08-24', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 15:11:03', '2024-10-06 15:11:03'),
(428, '01', 'CHA000054', 'INV000054', '01SV000054', '2024-08-24', 14, 'Md Lokman Hossain.', 'SV', 800.00, 'Cr', NULL, 'Invoice:INV000054, Name:Adapter (Input 100-220V, AC-0.6Amp, Output-24V DC-1.5Amp.), Qty:1.00 X 550.00\n\nName:Pay service, Qty:1.00 X 300.00\n', NULL, NULL, NULL, '2024-08-24', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 15:11:03', '2024-10-06 15:11:03'),
(429, '01', 'CHA000054', 'INV000054', '01SV000054', '2024-08-24', 147, 'Cash', 'SV', 800.00, 'Cr', 'Cash', 'Invoice:INV000054, Cash Received From: Md Lokman Hossain., Through Cash Paid Amount:800.00 TK\n', NULL, NULL, NULL, '2024-08-24', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 15:11:03', '2024-10-06 15:11:03'),
(430, '01', 'CHA000054', 'INV000054', '01SV000054', '2024-08-24', 11, 'Md Lokman Hossain.', 'SV', 800.00, 'Dr', 'Cash', 'Invoice:INV000054, Cash Received From: Md Lokman Hossain., Through Cash Paid Amount:800.00 TK\n', NULL, NULL, NULL, '2024-08-24', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 15:11:03', '2024-10-06 15:11:03'),
(431, '01', 'CHA000057', 'INV000057', '01SV000057', '2024-09-18', 149, 'Sales Account', 'SV', 320.00, 'Dr', NULL, 'Invoice:INV000057, Name:10 inch pp filter, Qty:1.00 X 120.00\n\nName:Transport, Qty:1.00 X 200.00\n', NULL, NULL, NULL, '2024-09-18', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 15:28:54', '2024-10-06 15:28:54'),
(432, '01', 'CHA000057', 'INV000057', '01SV000057', '2024-09-18', 14, 'Md Somrath.', 'SV', 320.00, 'Cr', NULL, 'Invoice:INV000057, Name:10 inch pp filter, Qty:1.00 X 120.00\n\nName:Transport, Qty:1.00 X 200.00\n', NULL, NULL, NULL, '2024-09-18', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 15:28:54', '2024-10-06 15:28:54'),
(433, '01', 'CHA000057', 'INV000057', '01SV000057', '2024-09-18', 149, 'Cash', 'SV', 320.00, 'Cr', 'Cash', 'Invoice:INV000057, Cash Received From: Md Somrath., Through Cash Paid Amount:320.00 TK\n', NULL, NULL, NULL, '2024-09-18', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 15:28:54', '2024-10-06 15:28:54'),
(434, '01', 'CHA000057', 'INV000057', '01SV000057', '2024-09-18', 11, 'Md Somrath.', 'SV', 320.00, 'Dr', 'Cash', 'Invoice:INV000057, Cash Received From: Md Somrath., Through Cash Paid Amount:320.00 TK\n', NULL, NULL, NULL, '2024-09-18', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 15:28:54', '2024-10-06 15:28:54'),
(435, '01', 'CHA000053', 'INV000053', '01SV000053', '2024-08-28', 140, 'Sales Account', 'SV', 920.00, 'Dr', NULL, 'Invoice:INV000053, Name:10 inch pp filter, Qty:1.00 X 120.00\n\nName:10 Inch CTO Filter, Qty:1.00 X 250.00\n\nName:10 Inch GAC Filter, Qty:1.00 X 250.00\n\nName:Transport, Qty:1.00 X 300.00\n', NULL, NULL, NULL, '2024-08-28', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 15:30:42', '2024-10-06 15:30:42'),
(436, '01', 'CHA000053', 'INV000053', '01SV000053', '2024-08-28', 14, 'Mr Adnan', 'SV', 920.00, 'Cr', NULL, 'Invoice:INV000053, Name:10 inch pp filter, Qty:1.00 X 120.00\n\nName:10 Inch CTO Filter, Qty:1.00 X 250.00\n\nName:10 Inch GAC Filter, Qty:1.00 X 250.00\n\nName:Transport, Qty:1.00 X 300.00\n', NULL, NULL, NULL, '2024-08-28', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 15:30:42', '2024-10-06 15:30:42'),
(437, '01', 'CHA000053', 'INV000053', '01SV000053', '2024-08-28', 140, 'Cash', 'SV', 920.00, 'Cr', 'Cash', 'Invoice:INV000053, Cash Received From: Mr Adnan, Through Cash Paid Amount:920.00 TK\n', NULL, NULL, NULL, '2024-08-28', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 15:30:42', '2024-10-06 15:30:42'),
(438, '01', 'CHA000053', 'INV000053', '01SV000053', '2024-08-28', 11, 'Mr Adnan', 'SV', 920.00, 'Dr', 'Cash', 'Invoice:INV000053, Cash Received From: Mr Adnan, Through Cash Paid Amount:920.00 TK\n', NULL, NULL, NULL, '2024-08-28', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 15:30:42', '2024-10-06 15:30:42'),
(439, '01', 'CHA000051', 'INV000051', '01SV000051', '2024-08-17', 124, 'Sales Account', 'SV', 920.00, 'Dr', NULL, 'Invoice:INV000051, Name:10 inch pp filter, Qty:1.00 X 120.00\n\nName:10 Inch CTO Filter, Qty:1.00 X 250.00\n\nName:10 Inch GAC Filter, Qty:1.00 X 250.00\n\nName:Transport, Qty:1.00 X 300.00\n', NULL, NULL, NULL, '2024-08-17', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 15:32:52', '2024-10-06 15:32:52'),
(440, '01', 'CHA000051', 'INV000051', '01SV000051', '2024-08-17', 14, 'Nur Al Mahedi.', 'SV', 920.00, 'Cr', NULL, 'Invoice:INV000051, Name:10 inch pp filter, Qty:1.00 X 120.00\n\nName:10 Inch CTO Filter, Qty:1.00 X 250.00\n\nName:10 Inch GAC Filter, Qty:1.00 X 250.00\n\nName:Transport, Qty:1.00 X 300.00\n', NULL, NULL, NULL, '2024-08-17', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 15:32:52', '2024-10-06 15:32:52'),
(441, '01', 'CHA000051', 'INV000051', '01SV000051', '2024-08-17', 124, 'Cash', 'SV', 920.00, 'Cr', 'Cash', 'Invoice:INV000051, Cash Received From: Nur Al Mahedi., Through Cash Paid Amount:920.00 TK\n', NULL, NULL, NULL, '2024-08-17', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 15:32:52', '2024-10-06 15:32:52'),
(442, '01', 'CHA000051', 'INV000051', '01SV000051', '2024-08-17', 11, 'Nur Al Mahedi.', 'SV', 920.00, 'Dr', 'Cash', 'Invoice:INV000051, Cash Received From: Nur Al Mahedi., Through Cash Paid Amount:920.00 TK\n', NULL, NULL, NULL, '2024-08-17', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 15:32:52', '2024-10-06 15:32:52'),
(451, '01', 'CHA000006', 'INV000006', '01SV000006', '2024-04-22', 116, 'Sales Account', 'SV', 10040.00, 'Dr', NULL, 'Invoice:INV000006, Name:RO-105, Qty:1.00 X 11500.00\n\nName:6mm Pipe., Qty:4.00 X 10.00\n', NULL, NULL, NULL, '2024-04-22', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 16:10:51', '2024-10-06 16:10:51'),
(452, '01', 'CHA000006', 'INV000006', '01SV000006', '2024-04-22', 14, 'Jihad Juice and fast Food.', 'SV', 10040.00, 'Cr', NULL, 'Invoice:INV000006, Name:RO-105, Qty:1.00 X 11500.00\n\nName:6mm Pipe., Qty:4.00 X 10.00\n', NULL, NULL, NULL, '2024-04-22', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 16:10:51', '2024-10-06 16:10:51'),
(453, '01', 'CHA000006', 'INV000006', '01SV000006', '2024-04-22', 116, 'Cash', 'SV', 10040.00, 'Cr', 'Cash', 'Invoice:INV000006, Cash Received From: Jihad Juice and fast Food., Through Cash Paid Amount:10,040.00 TK\n', NULL, NULL, NULL, '2024-04-22', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 16:10:51', '2024-10-06 16:10:51'),
(454, '01', 'CHA000006', 'INV000006', '01SV000006', '2024-04-22', 11, 'Jihad Juice and fast Food.', 'SV', 10040.00, 'Dr', 'Cash', 'Invoice:INV000006, Cash Received From: Jihad Juice and fast Food., Through Cash Paid Amount:10,040.00 TK\n', NULL, NULL, NULL, '2024-04-22', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 16:10:51', '2024-10-06 16:10:51'),
(455, '01', 'CHA000011', 'INV000011', '01SV000011', '2024-05-04', 121, 'Sales Account', 'SV', 9500.00, 'Dr', NULL, 'Invoice:INV000011, Name:RO-105, Qty:1.00 X 11500.00\n', NULL, NULL, NULL, '2024-05-04', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 16:17:48', '2024-10-06 16:17:48'),
(456, '01', 'CHA000011', 'INV000011', '01SV000011', '2024-05-04', 14, 'Mr Feroz Alam', 'SV', 9500.00, 'Cr', NULL, 'Invoice:INV000011, Name:RO-105, Qty:1.00 X 11500.00\n', NULL, NULL, NULL, '2024-05-04', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 16:17:48', '2024-10-06 16:17:48'),
(457, '01', 'CHA000011', 'INV000011', '01SV000011', '2024-05-04', 121, 'Cash', 'SV', 9500.00, 'Cr', 'Cash', 'Invoice:INV000011, Cash Received From: Mr Feroz Alam, Through Cash Paid Amount:9,500.00 TK\n', NULL, NULL, NULL, '2024-05-04', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 16:17:48', '2024-10-06 16:17:48'),
(458, '01', 'CHA000011', 'INV000011', '01SV000011', '2024-05-04', 11, 'Mr Feroz Alam', 'SV', 9500.00, 'Dr', 'Cash', 'Invoice:INV000011, Cash Received From: Mr Feroz Alam, Through Cash Paid Amount:9,500.00 TK\n', NULL, NULL, NULL, '2024-05-04', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 16:17:48', '2024-10-06 16:17:48'),
(459, '01', 'CHA000052', 'INV000052', '01SV000052', '2024-08-17', 133, 'Sales Account', 'SV', 120.00, 'Dr', NULL, 'Invoice:INV000052, Name:10 inch pp filter, Qty:1.00 X 120.00\n', NULL, NULL, NULL, '2024-08-17', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 16:45:55', '2024-10-06 16:45:55'),
(460, '01', 'CHA000052', 'INV000052', '01SV000052', '2024-08-17', 14, 'Sohel (Zia sir)', 'SV', 120.00, 'Cr', NULL, 'Invoice:INV000052, Name:10 inch pp filter, Qty:1.00 X 120.00\n', NULL, NULL, NULL, '2024-08-17', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 16:45:55', '2024-10-06 16:45:55'),
(461, '01', 'CHA000052', 'INV000052', '01SV000052', '2024-08-17', 133, 'Cash', 'SV', 120.00, 'Cr', 'Cash', 'Invoice:INV000052, Cash Received From: Sohel (Zia sir), Through Cash Paid Amount:120.00 TK\n', NULL, NULL, NULL, '2024-08-17', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 16:45:55', '2024-10-06 16:45:55'),
(462, '01', 'CHA000052', 'INV000052', '01SV000052', '2024-08-17', 11, 'Sohel (Zia sir)', 'SV', 120.00, 'Dr', 'Cash', 'Invoice:INV000052, Cash Received From: Sohel (Zia sir), Through Cash Paid Amount:120.00 TK\n', NULL, NULL, NULL, '2024-08-17', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 16:45:55', '2024-10-06 16:45:55'),
(463, '01', 'CHA000061', 'INV000061', '01SV000061', '2024-10-06', 115, 'Sales Account', 'SV', 9750.00, 'Dr', NULL, 'Invoice:INV000061, Name:RO-105 Qty:1 X 11500.00\n\nName:6mm Pipe. Qty:25 X 10\n', NULL, NULL, NULL, '2024-04-20', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 16:59:13', '2024-10-06 16:59:13'),
(464, '01', 'CHA000061', 'INV000061', '01SV000061', '2024-10-06', 14, 'Mr Sabbir', 'SV', 9750.00, 'Cr', NULL, 'Invoice:INV000061, Name:RO-105 Qty:1 X 11500.00\n\nName:6mm Pipe. Qty:25 X 10\n', NULL, NULL, NULL, '2024-04-20', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 16:59:13', '2024-10-06 16:59:13'),
(465, '01', 'CHA000061', 'INV000061', '01SV000061', '2024-10-06', 115, 'Cash', 'SV', 9750.00, 'Cr', 'Cash', 'Invoice:INV000061, Cash Received From Mr Sabbir, Cash Payment Amount:9,750.00 TK\n', '0', NULL, NULL, '2024-04-20', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 16:59:13', '2024-10-06 16:59:13'),
(466, '01', 'CHA000061', 'INV000061', '01SV000061', '2024-10-06', 11, 'Mr Sabbir', 'SV', 9750.00, 'Dr', 'Cash', 'Invoice:INV000061, Cash Received From Mr Sabbir, Cash Payment Amount:9,750.00 TK\n', '0', NULL, NULL, '2024-04-20', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 16:59:13', '2024-10-06 16:59:13'),
(467, '01', 'CHA000062', 'INV000062', '01SV000062', '2024-10-06', 146, 'Sales Account', 'SV', 9200.00, 'Dr', NULL, 'Invoice:INV000062, Name:RO-105 Qty:1 X 11500.00\n', NULL, NULL, NULL, '2024-07-14', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 17:13:46', '2024-10-06 17:13:46'),
(468, '01', 'CHA000062', 'INV000062', '01SV000062', '2024-10-06', 14, 'Istiaque Ahmed.', 'SV', 9200.00, 'Cr', NULL, 'Invoice:INV000062, Name:RO-105 Qty:1 X 11500.00\n', NULL, NULL, NULL, '2024-07-14', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 17:13:46', '2024-10-06 17:13:46'),
(469, '01', 'CHA000062', 'INV000062', '01SV000062', '2024-10-06', 146, 'Cash', 'SV', 9200.00, 'Cr', 'Cash', 'Invoice:INV000062, Cash Received From Istiaque Ahmed., Cash Payment Amount:9,200.00 TK\n', '0', NULL, NULL, '2024-07-14', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 17:13:46', '2024-10-06 17:13:46'),
(470, '01', 'CHA000062', 'INV000062', '01SV000062', '2024-10-06', 11, 'Istiaque Ahmed.', 'SV', 9200.00, 'Dr', 'Cash', 'Invoice:INV000062, Cash Received From Istiaque Ahmed., Cash Payment Amount:9,200.00 TK\n', '0', NULL, NULL, '2024-07-14', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 17:13:46', '2024-10-06 17:13:46'),
(475, '01', 'CHA000063', 'INV000063', '01SV000063', '2024-07-25', 147, 'Sales Account', 'SV', 240.00, 'Dr', NULL, 'Invoice:INV000063, Name:10 inch pp filter, Qty:2.00 X 120.00\n', NULL, NULL, NULL, '2024-07-25', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 17:19:18', '2024-10-06 17:19:18'),
(476, '01', 'CHA000063', 'INV000063', '01SV000063', '2024-07-25', 14, 'Md Lokman Hossain.', 'SV', 240.00, 'Cr', NULL, 'Invoice:INV000063, Name:10 inch pp filter, Qty:2.00 X 120.00\n', NULL, NULL, NULL, '2024-07-25', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 17:19:18', '2024-10-06 17:19:18'),
(477, '01', 'CHA000063', 'INV000063', '01SV000063', '2024-07-25', 147, 'Cash', 'SV', 240.00, 'Cr', 'Cash', 'Invoice:INV000063, Cash Received From: Md Lokman Hossain., Through Cash Paid Amount:240.00 TK\n', NULL, NULL, NULL, '2024-07-25', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 17:19:18', '2024-10-06 17:19:18'),
(478, '01', 'CHA000063', 'INV000063', '01SV000063', '2024-07-25', 11, 'Md Lokman Hossain.', 'SV', 240.00, 'Dr', 'Cash', 'Invoice:INV000063, Cash Received From: Md Lokman Hossain., Through Cash Paid Amount:240.00 TK\n', NULL, NULL, NULL, '2024-07-25', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 17:19:18', '2024-10-06 17:19:18'),
(479, '01', 'CHA000064', 'INV000064', '01SV000064', '2024-10-06', 125, 'Sales Account', 'SV', 700.00, 'Dr', NULL, 'Invoice:INV000064, Name:Inline Slim Mineral Filter Heron Qty:1 X 500\n\nName:10 inch pp filter Qty:1 X 120\n\nName:RO- Male Elbow Qty:2 X 25\n\nName:Transport Qty:1 X 200\n', NULL, NULL, NULL, '2024-07-25', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 17:25:36', '2024-10-06 17:25:36'),
(480, '01', 'CHA000064', 'INV000064', '01SV000064', '2024-10-06', 14, 'Md Saiful islam.', 'SV', 700.00, 'Cr', NULL, 'Invoice:INV000064, Name:Inline Slim Mineral Filter Heron Qty:1 X 500\n\nName:10 inch pp filter Qty:1 X 120\n\nName:RO- Male Elbow Qty:2 X 25\n\nName:Transport Qty:1 X 200\n', NULL, NULL, NULL, '2024-07-25', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 17:25:36', '2024-10-06 17:25:36'),
(481, '01', 'CHA000064', 'INV000064', '01SV000064', '2024-10-06', 125, 'Cash', 'SV', 700.00, 'Cr', 'Cash', 'Invoice:INV000064, Cash Received From Md Saiful islam., Cash Payment Amount:700.00 TK\n', '0', NULL, NULL, '2024-07-25', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 17:25:36', '2024-10-06 17:25:36'),
(482, '01', 'CHA000064', 'INV000064', '01SV000064', '2024-10-06', 11, 'Md Saiful islam.', 'SV', 700.00, 'Dr', 'Cash', 'Invoice:INV000064, Cash Received From Md Saiful islam., Cash Payment Amount:700.00 TK\n', '0', NULL, NULL, '2024-07-25', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 17:25:36', '2024-10-06 17:25:36'),
(483, '01', 'CHA000065', 'INV000065', '01SV000065', '2024-10-06', 129, 'Sales Account', 'SV', 920.00, 'Dr', NULL, 'Invoice:INV000065, Name:10 inch pp filter Qty:1 X 120\n\nName:10 Inch CTO Filter Qty:1 X 250\n\nName:10 Inch GAC Filter Qty:1 X 250\n\nName:Pay service Qty:1 X 300\n', NULL, NULL, NULL, '2024-07-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 17:30:58', '2024-10-06 17:30:58'),
(484, '01', 'CHA000065', 'INV000065', '01SV000065', '2024-10-06', 14, 'Shahanaz Bristy', 'SV', 920.00, 'Cr', NULL, 'Invoice:INV000065, Name:10 inch pp filter Qty:1 X 120\n\nName:10 Inch CTO Filter Qty:1 X 250\n\nName:10 Inch GAC Filter Qty:1 X 250\n\nName:Pay service Qty:1 X 300\n', NULL, NULL, NULL, '2024-07-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 17:30:58', '2024-10-06 17:30:58'),
(485, '01', 'CHA000065', 'INV000065', '01SV000065', '2024-10-06', 129, 'Cash', 'SV', 920.00, 'Cr', 'Cash', 'Invoice:INV000065, Cash Received From Shahanaz Bristy, Cash Payment Amount:920.00 TK\n', '0', NULL, NULL, '2024-07-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 17:30:58', '2024-10-06 17:30:58'),
(486, '01', 'CHA000065', 'INV000065', '01SV000065', '2024-10-06', 11, 'Shahanaz Bristy', 'SV', 920.00, 'Dr', 'Cash', 'Invoice:INV000065, Cash Received From Shahanaz Bristy, Cash Payment Amount:920.00 TK\n', '0', NULL, NULL, '2024-07-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 17:30:58', '2024-10-06 17:30:58'),
(487, '01', 'CHA000066', 'INV000066', '01SV000066', '2024-10-06', 118, 'Sales Account', 'SV', 700.00, 'Dr', NULL, 'Invoice:INV000066, Name:10 Inch CTO Filter Qty:1 X 250\n\nName:10 Inch GAC Filter Qty:1 X 250\n\nName:Transport Qty:1 X 100\n\nName:10 inch pp filter Qty:1 X 100\n', NULL, NULL, NULL, '2024-07-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 17:35:09', '2024-10-06 17:35:09'),
(488, '01', 'CHA000066', 'INV000066', '01SV000066', '2024-10-06', 14, 'Mr Monir Hossain.', 'SV', 700.00, 'Cr', NULL, 'Invoice:INV000066, Name:10 Inch CTO Filter Qty:1 X 250\n\nName:10 Inch GAC Filter Qty:1 X 250\n\nName:Transport Qty:1 X 100\n\nName:10 inch pp filter Qty:1 X 100\n', NULL, NULL, NULL, '2024-07-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 17:35:09', '2024-10-06 17:35:09'),
(489, '01', 'CHA000066', 'INV000066', '01SV000066', '2024-10-06', 118, 'Cash', 'SV', 700.00, 'Cr', 'Cash', 'Invoice:INV000066, Cash Received From Mr Monir Hossain., Cash Payment Amount:700.00 TK\n', '0', NULL, NULL, '2024-07-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 17:35:09', '2024-10-06 17:35:09'),
(490, '01', 'CHA000066', 'INV000066', '01SV000066', '2024-10-06', 11, 'Mr Monir Hossain.', 'SV', 700.00, 'Dr', 'Cash', 'Invoice:INV000066, Cash Received From Mr Monir Hossain., Cash Payment Amount:700.00 TK\n', '0', NULL, NULL, '2024-07-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 17:35:09', '2024-10-06 17:35:09'),
(491, '01', 'CHA000067', 'INV000067', '01SV000067', '2024-10-06', 149, 'Sales Account', 'SV', 9200.00, 'Dr', NULL, 'Invoice:INV000067, Name:RO-105 Qty:1 X 9200\n', NULL, NULL, NULL, '2024-08-01', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 17:37:46', '2024-10-06 17:37:46'),
(492, '01', 'CHA000067', 'INV000067', '01SV000067', '2024-10-06', 14, 'Md Somrath.', 'SV', 9200.00, 'Cr', NULL, 'Invoice:INV000067, Name:RO-105 Qty:1 X 9200\n', NULL, NULL, NULL, '2024-08-01', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 17:37:46', '2024-10-06 17:37:46'),
(493, '01', 'CHA000067', 'INV000067', '01SV000067', '2024-10-06', 149, 'Cash', 'SV', 9200.00, 'Cr', 'Cash', 'Invoice:INV000067, Cash Received From Md Somrath., Cash Payment Amount:9,200.00 TK\n', '0', NULL, NULL, '2024-08-01', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 17:37:46', '2024-10-06 17:37:46'),
(494, '01', 'CHA000067', 'INV000067', '01SV000067', '2024-10-06', 11, 'Md Somrath.', 'SV', 9200.00, 'Dr', 'Cash', 'Invoice:INV000067, Cash Received From Md Somrath., Cash Payment Amount:9,200.00 TK\n', '0', NULL, NULL, '2024-08-01', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 17:37:46', '2024-10-06 17:37:46'),
(495, '01', 'CHA000068', 'INV000068', '01SV000068', '2024-10-06', 133, 'Sales Account', 'SV', 1400.00, 'Dr', NULL, 'Invoice:INV000068, Name:10 inch pp filter Qty:5 X 120\n\nName:10 Inch CTO Filter Qty:1 X 250\n\nName:10 Inch GAC Filter Qty:1 X 250\n\nName:Transport Qty:1 X 300\n', NULL, NULL, NULL, '2024-08-01', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 17:40:29', '2024-10-06 17:40:29'),
(496, '01', 'CHA000068', 'INV000068', '01SV000068', '2024-10-06', 14, 'Sohel (Zia sir)', 'SV', 1400.00, 'Cr', NULL, 'Invoice:INV000068, Name:10 inch pp filter Qty:5 X 120\n\nName:10 Inch CTO Filter Qty:1 X 250\n\nName:10 Inch GAC Filter Qty:1 X 250\n\nName:Transport Qty:1 X 300\n', NULL, NULL, NULL, '2024-08-01', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 17:40:29', '2024-10-06 17:40:29'),
(497, '01', 'CHA000068', 'INV000068', '01SV000068', '2024-10-06', 133, 'Cash', 'SV', 1400.00, 'Cr', 'Cash', 'Invoice:INV000068, Cash Received From Sohel (Zia sir), Cash Payment Amount:1,400.00 TK\n', '0', NULL, NULL, '2024-08-01', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 17:40:29', '2024-10-06 17:40:29'),
(498, '01', 'CHA000068', 'INV000068', '01SV000068', '2024-10-06', 11, 'Sohel (Zia sir)', 'SV', 1400.00, 'Dr', 'Cash', 'Invoice:INV000068, Cash Received From Sohel (Zia sir), Cash Payment Amount:1,400.00 TK\n', '0', NULL, NULL, '2024-08-01', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 17:40:29', '2024-10-06 17:40:29'),
(499, '01', 'CHA000069', 'INV000069', '01SV000069', '2024-10-06', 128, 'Sales Account', 'SV', 920.00, 'Dr', NULL, 'Invoice:INV000069, Name:10 inch pp filter Qty:1 X 120\n\nName:10 Inch CTO Filter Qty:1 X 250\n\nName:10 Inch GAC Filter Qty:1 X 250\n\nName:Transport Qty:1 X 300\n', NULL, NULL, NULL, '2024-08-12', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 17:43:31', '2024-10-06 17:43:31'),
(500, '01', 'CHA000069', 'INV000069', '01SV000069', '2024-10-06', 14, 'Md Ziaul Haque(Zia Sir)', 'SV', 920.00, 'Cr', NULL, 'Invoice:INV000069, Name:10 inch pp filter Qty:1 X 120\n\nName:10 Inch CTO Filter Qty:1 X 250\n\nName:10 Inch GAC Filter Qty:1 X 250\n\nName:Transport Qty:1 X 300\n', NULL, NULL, NULL, '2024-08-12', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 17:43:31', '2024-10-06 17:43:31'),
(501, '01', 'CHA000069', 'INV000069', '01SV000069', '2024-10-06', 128, 'Cash', 'SV', 920.00, 'Cr', 'Cash', 'Invoice:INV000069, Cash Received From Md Ziaul Haque(Zia Sir), Cash Payment Amount:920.00 TK\n', '0', NULL, NULL, '2024-08-12', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 17:43:31', '2024-10-06 17:43:31'),
(502, '01', 'CHA000069', 'INV000069', '01SV000069', '2024-10-06', 11, 'Md Ziaul Haque(Zia Sir)', 'SV', 920.00, 'Dr', 'Cash', 'Invoice:INV000069, Cash Received From Md Ziaul Haque(Zia Sir), Cash Payment Amount:920.00 TK\n', '0', NULL, NULL, '2024-08-12', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 17:43:31', '2024-10-06 17:43:31'),
(503, '01', 'CHA000070', 'INV000070', '01SV000070', '2024-10-06', 130, 'Sales Account', 'SV', 1000.00, 'Dr', NULL, 'Invoice:INV000070, Name:10 inch pp filter Qty:1 X 120\n\nName:10 Inch CTO Filter Qty:1 X 250\n\nName:10 Inch GAC Filter Qty:1 X 250\n\nName:Inline Slim Mineral Filter Heron Qty:1 X 450\n', NULL, NULL, NULL, '2024-08-13', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 17:47:22', '2024-10-06 17:47:22'),
(504, '01', 'CHA000070', 'INV000070', '01SV000070', '2024-10-06', 14, 'Mr Emon', 'SV', 1000.00, 'Cr', NULL, 'Invoice:INV000070, Name:10 inch pp filter Qty:1 X 120\n\nName:10 Inch CTO Filter Qty:1 X 250\n\nName:10 Inch GAC Filter Qty:1 X 250\n\nName:Inline Slim Mineral Filter Heron Qty:1 X 450\n', NULL, NULL, NULL, '2024-08-13', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 17:47:22', '2024-10-06 17:47:22'),
(505, '01', 'CHA000070', 'INV000070', '01SV000070', '2024-10-06', 130, 'Cash', 'SV', 1000.00, 'Cr', 'Cash', 'Invoice:INV000070, Cash Received From Mr Emon, Cash Payment Amount:1,000.00 TK\n', '0', NULL, NULL, '2024-08-13', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 17:47:22', '2024-10-06 17:47:22'),
(506, '01', 'CHA000070', 'INV000070', '01SV000070', '2024-10-06', 11, 'Mr Emon', 'SV', 1000.00, 'Dr', 'Cash', 'Invoice:INV000070, Cash Received From Mr Emon, Cash Payment Amount:1,000.00 TK\n', '0', NULL, NULL, '2024-08-13', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 17:47:22', '2024-10-06 17:47:22'),
(519, '01', 'CHA000071', 'INV000071', '01SV000071', '2024-08-14', 122, 'Sales Account', 'SV', 900.00, 'Dr', NULL, 'Invoice:INV000071, Name:10 inch pp filter, Qty:1.00 X 120.00\n\nName:10 Inch CTO Filter, Qty:1.00 X 250.00\n\nName:10 Inch GAC Filter, Qty:1.00 X 250.00\n\nName:Transport, Qty:1.00 X 300.00\n', NULL, NULL, NULL, '2024-08-14', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 23:19:05', '2024-10-06 23:19:05'),
(520, '01', 'CHA000071', 'INV000071', '01SV000071', '2024-08-14', 14, 'Jafor Raja', 'SV', 900.00, 'Cr', NULL, 'Invoice:INV000071, Name:10 inch pp filter, Qty:1.00 X 120.00\n\nName:10 Inch CTO Filter, Qty:1.00 X 250.00\n\nName:10 Inch GAC Filter, Qty:1.00 X 250.00\n\nName:Transport, Qty:1.00 X 300.00\n', NULL, NULL, NULL, '2024-08-14', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 23:19:05', '2024-10-06 23:19:05'),
(521, '01', 'CHA000071', 'INV000071', '01SV000071', '2024-08-14', 122, 'Cash', 'SV', 900.00, 'Cr', 'Cash', 'Invoice:INV000071, Cash Received From: Jafor Raja, Through Cash Paid Amount:900.00 TK\n', NULL, NULL, NULL, '2024-08-14', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 23:19:05', '2024-10-06 23:19:05'),
(522, '01', 'CHA000071', 'INV000071', '01SV000071', '2024-08-14', 11, 'Jafor Raja', 'SV', 900.00, 'Dr', 'Cash', 'Invoice:INV000071, Cash Received From: Jafor Raja, Through Cash Paid Amount:900.00 TK\n', NULL, NULL, NULL, '2024-08-14', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 23:19:05', '2024-10-06 23:19:05'),
(523, '01', 'CHA000072', 'INV000072', '01SV000072', '2024-10-06', 125, 'Sales Account', 'SV', 300.00, 'Dr', NULL, 'Invoice:INV000072, Name:10 inch pp filter Qty:1 X 120\n\nName:Transport Qty:1 X 180\n', NULL, NULL, NULL, '2024-09-19', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 23:27:42', '2024-10-06 23:27:42'),
(524, '01', 'CHA000072', 'INV000072', '01SV000072', '2024-10-06', 14, 'Md Saiful islam.', 'SV', 300.00, 'Cr', NULL, 'Invoice:INV000072, Name:10 inch pp filter Qty:1 X 120\n\nName:Transport Qty:1 X 180\n', NULL, NULL, NULL, '2024-09-19', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 23:27:42', '2024-10-06 23:27:42'),
(525, '01', 'CHA000072', 'INV000072', '01SV000072', '2024-10-06', 125, 'Cash', 'SV', 300.00, 'Cr', 'Cash', 'Invoice:INV000072, Cash Received From Md Saiful islam., Cash Payment Amount:300.00 TK\n', '0', NULL, NULL, '2024-09-19', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 23:27:42', '2024-10-06 23:27:42'),
(526, '01', 'CHA000072', 'INV000072', '01SV000072', '2024-10-06', 11, 'Md Saiful islam.', 'SV', 300.00, 'Dr', 'Cash', 'Invoice:INV000072, Cash Received From Md Saiful islam., Cash Payment Amount:300.00 TK\n', '0', NULL, NULL, '2024-09-19', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 23:27:42', '2024-10-06 23:27:42'),
(527, '01', 'CHA000073', 'INV000073', '01SV000073', '2024-10-06', 150, 'Sales Account', 'SV', 10000.00, 'Dr', NULL, 'Invoice:INV000073, Name:RO-105 Qty:1 X 10500.00\n', NULL, NULL, NULL, '2024-09-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 23:33:51', '2024-10-06 23:33:51'),
(528, '01', 'CHA000073', 'INV000073', '01SV000073', '2024-10-06', 14, 'Dr. Tahseen Ali.', 'SV', 10000.00, 'Cr', NULL, 'Invoice:INV000073, Name:RO-105 Qty:1 X 10500.00\n', NULL, NULL, NULL, '2024-09-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 23:33:51', '2024-10-06 23:33:51'),
(529, '01', 'CHA000073', 'INV000073', '01SV000073', '2024-10-06', 150, 'Cash', 'SV', 10000.00, 'Cr', 'Cash', 'Invoice:INV000073, Cash Received From Dr. Tahseen Ali., Cash Payment Amount:10,000.00 TK\n', '0', NULL, NULL, '2024-09-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 23:33:51', '2024-10-06 23:33:51'),
(530, '01', 'CHA000073', 'INV000073', '01SV000073', '2024-10-06', 11, 'Dr. Tahseen Ali.', 'SV', 10000.00, 'Dr', 'Cash', 'Invoice:INV000073, Cash Received From Dr. Tahseen Ali., Cash Payment Amount:10,000.00 TK\n', '0', NULL, NULL, '2024-09-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-06 23:33:51', '2024-10-06 23:33:51'),
(531, '01', 'CHA000074', 'INV000074', '01SV000074', '2024-10-06', 151, 'Sales Account', 'SV', 9000.00, 'Dr', NULL, 'Invoice:INV000074, Name:RO-105 Qty:1 X 9000.00\n', NULL, NULL, NULL, '2024-10-03', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-07 00:11:10', '2024-10-07 00:11:10'),
(532, '01', 'CHA000074', 'INV000074', '01SV000074', '2024-10-06', 14, 'Md.Liton', 'SV', 9000.00, 'Cr', NULL, 'Invoice:INV000074, Name:RO-105 Qty:1 X 9000.00\n', NULL, NULL, NULL, '2024-10-03', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-07 00:11:10', '2024-10-07 00:11:10'),
(533, '01', 'CHA000074', 'INV000074', '01SV000074', '2024-10-06', 151, 'Cash', 'SV', 9000.00, 'Cr', 'Cash', 'Invoice:INV000074, Cash Received From Md.Liton, Cash Payment Amount:9,000.00 TK\n', '0', NULL, NULL, '2024-10-03', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-07 00:11:10', '2024-10-07 00:11:10'),
(534, '01', 'CHA000074', 'INV000074', '01SV000074', '2024-10-06', 11, 'Md.Liton', 'SV', 9000.00, 'Dr', 'Cash', 'Invoice:INV000074, Cash Received From Md.Liton, Cash Payment Amount:9,000.00 TK\n', '0', NULL, NULL, '2024-10-03', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-07 00:11:10', '2024-10-07 00:11:10'),
(535, '01', 'CHA000075', 'INV000075', '01SV000075', '2024-10-06', 152, 'Sales Account', 'SV', 420.00, 'Dr', NULL, 'Invoice:INV000075, Name:10 inch pp filter Qty:1 X 120\n\nName:Transport Qty:1 X 300\n', NULL, NULL, NULL, '2024-10-05', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-07 00:13:03', '2024-10-07 00:13:03'),
(536, '01', 'CHA000075', 'INV000075', '01SV000075', '2024-10-06', 14, 'Khorshed', 'SV', 420.00, 'Cr', NULL, 'Invoice:INV000075, Name:10 inch pp filter Qty:1 X 120\n\nName:Transport Qty:1 X 300\n', NULL, NULL, NULL, '2024-10-05', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-07 00:13:03', '2024-10-07 00:13:03'),
(537, '01', 'CHA000075', 'INV000075', '01SV000075', '2024-10-06', 152, 'Cash', 'SV', 420.00, 'Cr', 'Cash', 'Invoice:INV000075, Cash Received From Khorshed, Cash Payment Amount:420.00 TK\n', '0', NULL, NULL, '2024-10-05', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-07 00:13:03', '2024-10-07 00:13:03'),
(538, '01', 'CHA000075', 'INV000075', '01SV000075', '2024-10-06', 11, 'Khorshed', 'SV', 420.00, 'Dr', 'Cash', 'Invoice:INV000075, Cash Received From Khorshed, Cash Payment Amount:420.00 TK\n', '0', NULL, NULL, '2024-10-05', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-07 00:13:03', '2024-10-07 00:13:03'),
(541, '01', NULL, 'PUR000002', '01PV000002', '2024-01-30', 13, 'ABM engineering', 'PV', 944700.00, 'Dr', NULL, 'Invoice:PUR000002, Name:RO-105, Qty:100.00 X 7100.00, Total:710000\n\nName:DF-105, Qty:100.00 X 2347.00, Total:234700\n', NULL, NULL, NULL, '2024-01-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-17 17:05:34', '2024-10-17 17:05:34'),
(542, '01', NULL, 'PUR000002', '01PV000002', '2024-01-30', 112, 'Purchase Account', 'PV', 944700.00, 'Cr', NULL, 'Invoice:PUR000002, Name:RO-105, Qty:100.00 X 7100.00, Total:710000\n\nName:DF-105, Qty:100.00 X 2347.00, Total:234700\n', NULL, NULL, NULL, '2024-01-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-17 17:05:34', '2024-10-17 17:05:34'),
(543, '01', NULL, 'PUR000002', '01PV000002', '2024-01-30', 112, 'Cash', 'PV', 944700.00, 'Dr', 'Cash in hand', 'Invoice:PUR000002, Cash Payment To: ABM engineering, Through Cash Payment Amount:9,44,700.00 TK \n', NULL, NULL, NULL, '2024-01-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-17 17:05:34', '2024-10-17 17:05:34'),
(544, '01', NULL, 'PUR000002', '01PV000002', '2024-01-30', 11, 'ABM engineering', 'PV', 944700.00, 'Cr', 'Cash in hand', 'Invoice:PUR000002, Cash Payment To: ABM engineering, Through Cash Payment Amount:9,44,700.00 TK \n', NULL, NULL, NULL, '2024-01-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-17 17:05:34', '2024-10-17 17:05:34'),
(545, '01', NULL, 'PUR000021', '01PV000021', '2024-01-30', 13, 'ABM engineering', 'PV', 4500.00, 'Dr', NULL, 'Invoice:PUR000021, Name:6mm Pipe., Qty:1000 X 4.500, Total:4500\n', NULL, NULL, NULL, '2024-01-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-17 23:46:29', '2024-10-17 23:46:29'),
(546, '01', NULL, 'PUR000021', '01PV000021', '2024-01-30', 112, 'Purchase Account', 'PV', 4500.00, 'Cr', NULL, 'Invoice:PUR000021, Name:6mm Pipe., Qty:1000 X 4.500, Total:4500\n', NULL, NULL, NULL, '2024-01-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-17 23:46:29', '2024-10-17 23:46:29'),
(547, '01', NULL, 'PUR000021', '01PV000021', '2024-01-30', 112, NULL, 'PV', 4500.00, 'Dr', NULL, 'Invoice:PUR000021,  Payment To: ABM engineering, Through Cash Payment Amount:4,500.00 TK \n', '0', NULL, NULL, '2024-01-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-17 23:46:29', '2024-10-17 23:46:29'),
(548, '01', NULL, 'PUR000021', '01PV000021', '2024-01-30', NULL, 'ABM engineering', 'PV', 4500.00, 'Cr', NULL, 'Invoice:PUR000021,  Payment To: ABM engineering, Through Cash Payment Amount:4,500.00 TK \n', '0', NULL, NULL, '2024-01-30', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-17 23:46:29', '2024-10-17 23:46:29'),
(549, '01', 'CHA000076', 'INV000076', '01SV000076', '2024-10-02', 153, 'Sales Account', 'SV', 9200.00, 'Dr', NULL, 'Invoice:INV000076, Name:RO-105, Qty:1 X 10500.000, , Total:9200\n', NULL, NULL, NULL, '2024-10-02', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-19 22:19:23', '2024-10-19 22:19:23'),
(550, '01', 'CHA000076', 'INV000076', '01SV000076', '2024-10-02', 14, 'AKM Haruner Rashid', 'SV', 9200.00, 'Cr', NULL, 'Invoice:INV000076, Name:RO-105, Qty:1 X 10500.000, , Total:9200\n', NULL, NULL, NULL, '2024-10-02', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-19 22:19:23', '2024-10-19 22:19:23'),
(551, '01', 'CHA000076', 'INV000076', '01SV000076', '2024-10-02', 153, 'Cash', 'SV', 9200.00, 'Cr', 'Cash in hand', 'Invoice:INV000076, Cash Received From: AKM Haruner Rashid, Through Cash Received Amount:9,200.00 TK \n', NULL, NULL, NULL, '2024-10-02', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-19 22:19:23', '2024-10-19 22:19:23'),
(552, '01', 'CHA000076', 'INV000076', '01SV000076', '2024-10-02', 11, 'AKM Haruner Rashid', 'SV', 9200.00, 'Dr', 'Cash in hand', 'Invoice:INV000076, Cash Received From: AKM Haruner Rashid, Through Cash Received Amount:9,200.00 TK \n', NULL, NULL, NULL, '2024-10-02', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-19 22:19:23', '2024-10-19 22:19:23'),
(553, '01', 'CHA000077', 'INV000077', '01SV000077', '2024-10-09', 154, 'Sales Account', 'SV', 12000.00, 'Dr', NULL, 'Invoice:INV000077, Name:RO Machine CT40, Qty:1 X 12000, Total:12000\n', NULL, NULL, NULL, '2024-10-09', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-19 22:46:28', '2024-10-19 22:46:28'),
(554, '01', 'CHA000077', 'INV000077', '01SV000077', '2024-10-09', 14, 'Mr.Shimul', 'SV', 12000.00, 'Cr', NULL, 'Invoice:INV000077, Name:RO Machine CT40, Qty:1 X 12000, Total:12000\n', NULL, NULL, NULL, '2024-10-09', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-19 22:46:28', '2024-10-19 22:46:28'),
(555, '01', 'CHA000077', 'INV000077', '01SV000077', '2024-10-09', 154, 'Cash', 'SV', 12000.00, 'Cr', 'Cash in hand', 'Invoice:INV000077, Cash Received From: Mr.Shimul, Through Cash Received Amount:12,000.00 TK \n', '0', NULL, NULL, '2024-10-09', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-19 22:46:28', '2024-10-19 22:46:28'),
(556, '01', 'CHA000077', 'INV000077', '01SV000077', '2024-10-09', 11, 'Mr.Shimul', 'SV', 12000.00, 'Dr', 'Cash in hand', 'Invoice:INV000077, Cash Received From: Mr.Shimul, Through Cash Received Amount:12,000.00 TK \n', '0', NULL, NULL, '2024-10-09', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-19 22:46:28', '2024-10-19 22:46:28'),
(561, '01', 'CHA000079', 'INV000079', '01SV000079', '2024-10-07', 138, 'Sales Account', 'SV', 700.00, 'Dr', NULL, 'Invoice:INV000079, Name:10 inch pp filter, Qty:1 X 120, Total:120\n\nName:10 Inch CTO Filter, Qty:1 X 250, Total:250\n\nName:10 Inch GAC Filter, Qty:1 X 250, Total:250\n\nName:Transport, Qty:1 X 300, Total:80\n', NULL, NULL, NULL, '2024-10-07', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-19 23:19:22', '2024-10-19 23:19:22'),
(562, '01', 'CHA000079', 'INV000079', '01SV000079', '2024-10-07', 14, 'Mr Robiul.', 'SV', 700.00, 'Cr', NULL, 'Invoice:INV000079, Name:10 inch pp filter, Qty:1 X 120, Total:120\n\nName:10 Inch CTO Filter, Qty:1 X 250, Total:250\n\nName:10 Inch GAC Filter, Qty:1 X 250, Total:250\n\nName:Transport, Qty:1 X 300, Total:80\n', NULL, NULL, NULL, '2024-10-07', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-19 23:19:22', '2024-10-19 23:19:22'),
(563, '01', 'CHA000079', 'INV000079', '01SV000079', '2024-10-07', 138, 'Cash', 'SV', 700.00, 'Cr', 'Cash in hand', 'Invoice:INV000079, Cash Received From: Mr Robiul., Through Cash Received Amount:700.00 TK \n', '0', NULL, NULL, '2024-10-07', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-19 23:19:22', '2024-10-19 23:19:22'),
(564, '01', 'CHA000079', 'INV000079', '01SV000079', '2024-10-07', 11, 'Mr Robiul.', 'SV', 700.00, 'Dr', 'Cash in hand', 'Invoice:INV000079, Cash Received From: Mr Robiul., Through Cash Received Amount:700.00 TK \n', '0', NULL, NULL, '2024-10-07', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-19 23:19:22', '2024-10-19 23:19:22'),
(591, '01', 'CHA000083', 'INV000083', '01SV000083', '2024-07-27', 142, 'Sales Account', 'SV', 198.00, 'Dr', NULL, 'Invoice:INV000083, Name:10 inch pp filter, Qty:1.00 X 120.00, , Total:120\n\nName:Pay service, Qty:1.00 X 78.00, , Total:78\n', NULL, NULL, NULL, '2024-07-27', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-30 16:12:32', '2024-10-30 16:12:32'),
(592, '01', 'CHA000083', 'INV000083', '01SV000083', '2024-07-27', 14, 'Sonali Paper and Board Mills.', 'SV', 198.00, 'Cr', NULL, 'Invoice:INV000083, Name:10 inch pp filter, Qty:1.00 X 120.00, , Total:120\n\nName:Pay service, Qty:1.00 X 78.00, , Total:78\n', NULL, NULL, NULL, '2024-07-27', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-30 16:12:32', '2024-10-30 16:12:32'),
(593, '01', 'CHA000083', 'INV000083', '01SV000083', '2024-07-27', 142, 'Cash', 'SV', 198.00, 'Cr', 'Cash in hand', 'Invoice:INV000083, Cash Received From: Sonali Paper and Board Mills., Through Cash Received Amount:198.00 TK \n', NULL, NULL, NULL, '2024-07-27', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-30 16:12:32', '2024-10-30 16:12:32'),
(594, '01', 'CHA000083', 'INV000083', '01SV000083', '2024-07-27', 11, 'Sonali Paper and Board Mills.', 'SV', 198.00, 'Dr', 'Cash in hand', 'Invoice:INV000083, Cash Received From: Sonali Paper and Board Mills., Through Cash Received Amount:198.00 TK \n', NULL, NULL, NULL, '2024-07-27', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-30 16:12:32', '2024-10-30 16:12:32'),
(595, '01', 'CHA000055', 'INV000055', '01SV000055', '2024-09-12', 142, 'Sales Account', 'SV', 698.00, 'Dr', NULL, 'Invoice:INV000055, Name:10 inch pp filter, Qty:1.00 X 120.00, , Total:120\n\nName:10 Inch CTO Filter, Qty:1.00 X 250.00, , Total:250\n\nName:10 Inch GAC Filter, Qty:1.00 X 250.00, , Total:250\n\nName:Pay service, Qty:1 X 78, , Total:78\n', NULL, NULL, NULL, '2024-09-12', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-30 16:14:36', '2024-10-30 16:14:36'),
(596, '01', 'CHA000055', 'INV000055', '01SV000055', '2024-09-12', 14, 'Sonali Paper and Board Mills.', 'SV', 698.00, 'Cr', NULL, 'Invoice:INV000055, Name:10 inch pp filter, Qty:1.00 X 120.00, , Total:120\n\nName:10 Inch CTO Filter, Qty:1.00 X 250.00, , Total:250\n\nName:10 Inch GAC Filter, Qty:1.00 X 250.00, , Total:250\n\nName:Pay service, Qty:1 X 78, , Total:78\n', NULL, NULL, NULL, '2024-09-12', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-30 16:14:36', '2024-10-30 16:14:36'),
(597, '01', 'CHA000055', 'INV000055', '01SV000055', '2024-09-12', 142, 'Cash', 'SV', 698.00, 'Cr', 'Cash in hand', 'Invoice:INV000055, Cash Received From: Sonali Paper and Board Mills., Through Cash Received Amount:698.00 TK \n', NULL, NULL, NULL, '2024-09-12', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-30 16:14:36', '2024-10-30 16:14:36'),
(598, '01', 'CHA000055', 'INV000055', '01SV000055', '2024-09-12', 11, 'Sonali Paper and Board Mills.', 'SV', 698.00, 'Dr', 'Cash in hand', 'Invoice:INV000055, Cash Received From: Sonali Paper and Board Mills., Through Cash Received Amount:698.00 TK \n', NULL, NULL, NULL, '2024-09-12', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-30 16:14:36', '2024-10-30 16:14:36'),
(599, '01', 'CHA000080', 'INV000080', '01SV000080', '2024-10-07', 142, 'Sales Account', 'SV', 198.00, 'Dr', NULL, 'Invoice:INV000080, Name:10 inch pp filter, Qty:1.00 X 120.00, , Total:120\n\nName:Pay service, Qty:1 X 78, , Total:78\n', NULL, NULL, NULL, '2024-10-07', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-30 16:17:12', '2024-10-30 16:17:12'),
(600, '01', 'CHA000080', 'INV000080', '01SV000080', '2024-10-07', 14, 'Sonali Paper and Board Mills.', 'SV', 198.00, 'Cr', NULL, 'Invoice:INV000080, Name:10 inch pp filter, Qty:1.00 X 120.00, , Total:120\n\nName:Pay service, Qty:1 X 78, , Total:78\n', NULL, NULL, NULL, '2024-10-07', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-30 16:17:12', '2024-10-30 16:17:12'),
(601, '01', 'CHA000080', 'INV000080', '01SV000080', '2024-10-07', 142, 'Cash', 'SV', 198.00, 'Cr', 'Cash in hand', 'Invoice:INV000080, Cash Received From: Sonali Paper and Board Mills., Through Cash Received Amount:198.00 TK \n', NULL, NULL, NULL, '2024-10-07', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-30 16:17:12', '2024-10-30 16:17:12'),
(602, '01', 'CHA000080', 'INV000080', '01SV000080', '2024-10-07', 11, 'Sonali Paper and Board Mills.', 'SV', 198.00, 'Dr', 'Cash in hand', 'Invoice:INV000080, Cash Received From: Sonali Paper and Board Mills., Through Cash Received Amount:198.00 TK \n', NULL, NULL, NULL, '2024-10-07', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-30 16:17:12', '2024-10-30 16:17:12'),
(603, '01', 'CHA000081', 'INV000081', '01SV000081', '2024-10-16', 142, 'Sales Account', 'SV', 1028.00, 'Dr', NULL, 'Invoice:INV000081, Name:Small American Faucet., Qty:1.00 X 950.00, , Total:950\n\nName:Pay service, Qty:1 X 78, , Total:78\n', NULL, NULL, NULL, '2024-10-16', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-30 16:19:00', '2024-10-30 16:19:00'),
(604, '01', 'CHA000081', 'INV000081', '01SV000081', '2024-10-16', 14, 'Sonali Paper and Board Mills.', 'SV', 1028.00, 'Cr', NULL, 'Invoice:INV000081, Name:Small American Faucet., Qty:1.00 X 950.00, , Total:950\n\nName:Pay service, Qty:1 X 78, , Total:78\n', NULL, NULL, NULL, '2024-10-16', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-30 16:19:00', '2024-10-30 16:19:00'),
(605, '01', 'CHA000081', 'INV000081', '01SV000081', '2024-10-16', 142, 'Cash', 'SV', 1028.00, 'Cr', 'Cash in hand', 'Invoice:INV000081, Cash Received From: Sonali Paper and Board Mills., Through Cash Received Amount:1,028.00 TK \n', NULL, NULL, NULL, '2024-10-16', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-30 16:19:00', '2024-10-30 16:19:00');
INSERT INTO `finance_transactions` (`id`, `company_code`, `delivery_challan_no`, `invoice_no`, `voucher_no`, `voucher_date`, `acid`, `to_acc_name`, `type`, `amount`, `balance_type`, `payment_type`, `narration`, `cheque_no`, `cheque_date`, `cheque_type`, `transaction_date`, `transaction_by`, `invoice_type`, `pending_adjustment`, `status`, `done_by`, `updated_by`, `created_at`, `updated_at`) VALUES
(606, '01', 'CHA000081', 'INV000081', '01SV000081', '2024-10-16', 11, 'Sonali Paper and Board Mills.', 'SV', 1028.00, 'Dr', 'Cash in hand', 'Invoice:INV000081, Cash Received From: Sonali Paper and Board Mills., Through Cash Received Amount:1,028.00 TK \n', NULL, NULL, NULL, '2024-10-16', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-30 16:19:00', '2024-10-30 16:19:00'),
(607, '01', 'CHA000082', 'INV000082', '01SV000082', '2024-10-19', 142, 'Sales Account', 'SV', 578.00, 'Dr', NULL, 'Invoice:INV000082, Name:10 inch pp filter, Qty:1.00 X 100.00, , Total:100\n\nName:10 Inch CTO Filter, Qty:1.00 X 200.00, , Total:200\n\nName:10 Inch GAC Filter, Qty:1.00 X 200.00, , Total:200\n\nName:Pay service, Qty:1 X 78, , Total:78\n', NULL, NULL, NULL, '2024-10-19', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-30 16:21:03', '2024-10-30 16:21:03'),
(608, '01', 'CHA000082', 'INV000082', '01SV000082', '2024-10-19', 14, 'Sonali Paper and Board Mills.', 'SV', 578.00, 'Cr', NULL, 'Invoice:INV000082, Name:10 inch pp filter, Qty:1.00 X 100.00, , Total:100\n\nName:10 Inch CTO Filter, Qty:1.00 X 200.00, , Total:200\n\nName:10 Inch GAC Filter, Qty:1.00 X 200.00, , Total:200\n\nName:Pay service, Qty:1 X 78, , Total:78\n', NULL, NULL, NULL, '2024-10-19', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-30 16:21:03', '2024-10-30 16:21:03'),
(609, '01', 'CHA000082', 'INV000082', '01SV000082', '2024-10-19', 142, 'Cash', 'SV', 578.00, 'Cr', 'Cash in hand', 'Invoice:INV000082, Cash Received From: Sonali Paper and Board Mills., Through Cash Received Amount:578.00 TK \n', NULL, NULL, NULL, '2024-10-19', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-30 16:21:03', '2024-10-30 16:21:03'),
(610, '01', 'CHA000082', 'INV000082', '01SV000082', '2024-10-19', 11, 'Sonali Paper and Board Mills.', 'SV', 578.00, 'Dr', 'Cash in hand', 'Invoice:INV000082, Cash Received From: Sonali Paper and Board Mills., Through Cash Received Amount:578.00 TK \n', NULL, NULL, NULL, '2024-10-19', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-30 16:21:03', '2024-10-30 16:21:03'),
(611, '01', 'CHA000084', 'INV000084', '01SV000084', '2024-10-21', 158, 'Sales Account', 'SV', 1300.00, 'Dr', NULL, 'Invoice:INV000084, Name:10 inch pp filter, Qty:1 X 100, Total:100\n\nName:10 Inch CTO Filter, Qty:1 X 350, Total:350\n\nName:10 Inch GAC Filter, Qty:1 X 350, Total:350\n\nName:Pay service, Qty:1 X 500, Total:500\n', NULL, NULL, NULL, '2024-10-21', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-30 17:53:24', '2024-10-30 17:53:24'),
(612, '01', 'CHA000084', 'INV000084', '01SV000084', '2024-10-21', 14, 'Exim Bank', 'SV', 1300.00, 'Cr', NULL, 'Invoice:INV000084, Name:10 inch pp filter, Qty:1 X 100, Total:100\n\nName:10 Inch CTO Filter, Qty:1 X 350, Total:350\n\nName:10 Inch GAC Filter, Qty:1 X 350, Total:350\n\nName:Pay service, Qty:1 X 500, Total:500\n', NULL, NULL, NULL, '2024-10-21', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-30 17:53:24', '2024-10-30 17:53:24'),
(613, '01', 'CHA000084', 'INV000084', '01SV000084', '2024-10-21', 158, 'Cash', 'SV', 1300.00, 'Cr', 'Cash in hand', 'Invoice:INV000084, Cash Received From: Exim Bank, Through Cash Received Amount:1,300.00 TK \n', '0', NULL, NULL, '2024-10-21', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-30 17:53:24', '2024-10-30 17:53:24'),
(614, '01', 'CHA000084', 'INV000084', '01SV000084', '2024-10-21', 11, 'Exim Bank', 'SV', 1300.00, 'Dr', 'Cash in hand', 'Invoice:INV000084, Cash Received From: Exim Bank, Through Cash Received Amount:1,300.00 TK \n', '0', NULL, NULL, '2024-10-21', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-30 17:53:24', '2024-10-30 17:53:24'),
(615, '01', 'CHA000085', 'INV000085', '01SV000085', '2024-09-23', 127, 'Sales Account', 'SV', 700.00, 'Dr', NULL, 'Invoice:INV000085, Name:10 inch pp filter, Qty:1 X 100, Total:100\n\nName:10 Inch CTO Filter, Qty:1 X 250, Total:250\n\nName:10 Inch GAC Filter, Qty:1 X 250, Total:250\n\nName:Transport, Qty:1 X 100, Total:100\n', NULL, NULL, NULL, '2024-09-23', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-30 18:30:44', '2024-10-30 18:30:44'),
(616, '01', 'CHA000085', 'INV000085', '01SV000085', '2024-09-23', 14, 'Mr Tanvir (  Rubel Acc)', 'SV', 700.00, 'Cr', NULL, 'Invoice:INV000085, Name:10 inch pp filter, Qty:1 X 100, Total:100\n\nName:10 Inch CTO Filter, Qty:1 X 250, Total:250\n\nName:10 Inch GAC Filter, Qty:1 X 250, Total:250\n\nName:Transport, Qty:1 X 100, Total:100\n', NULL, NULL, NULL, '2024-09-23', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-30 18:30:44', '2024-10-30 18:30:44'),
(617, '01', 'CHA000085', 'INV000085', '01SV000085', '2024-09-23', 127, 'Cash', 'SV', 700.00, 'Cr', 'Cash in hand', 'Invoice:INV000085, Cash Received From: Mr Tanvir (  Rubel Acc), Through Cash Received Amount:700.00 TK \n', '0', NULL, NULL, '2024-09-23', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-30 18:30:44', '2024-10-30 18:30:44'),
(618, '01', 'CHA000085', 'INV000085', '01SV000085', '2024-09-23', 11, 'Mr Tanvir (  Rubel Acc)', 'SV', 700.00, 'Dr', 'Cash in hand', 'Invoice:INV000085, Cash Received From: Mr Tanvir (  Rubel Acc), Through Cash Received Amount:700.00 TK \n', '0', NULL, NULL, '2024-09-23', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-10-30 18:30:44', '2024-10-30 18:30:44'),
(619, '01', 'CHA000086', 'INV000086', '01SV000086', '2024-10-10', 128, 'Sales Account', 'SV', 9500.00, 'Dr', NULL, 'Invoice:INV000086, Name:RO-105, Qty:1 X 9500, Total:9500\n', NULL, NULL, NULL, '2024-10-10', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 22:10:07', '2024-11-19 22:10:07'),
(620, '01', 'CHA000086', 'INV000086', '01SV000086', '2024-10-10', 14, 'Md Ziaul Haque(Zia Sir)', 'SV', 9500.00, 'Cr', NULL, 'Invoice:INV000086, Name:RO-105, Qty:1 X 9500, Total:9500\n', NULL, NULL, NULL, '2024-10-10', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 22:10:07', '2024-11-19 22:10:07'),
(621, '01', 'CHA000087', 'INV000087', '01SV000087', '2024-10-23', 159, 'Sales Account', 'SV', 920.00, 'Dr', NULL, 'Invoice:INV000087, Name:10 inch pp filter, Qty:1 X 120, Total:120\n\nName:10 Inch CTO Filter, Qty:1 X 250, Total:250\n\nName:10 Inch GAC Filter, Qty:1 X 250, Total:250\n\nName:Transport, Qty:1 X 300, Total:300\n', NULL, NULL, NULL, '2024-10-23', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 22:17:11', '2024-11-19 22:17:11'),
(622, '01', 'CHA000087', 'INV000087', '01SV000087', '2024-10-23', 14, 'Mrs. Nazma', 'SV', 920.00, 'Cr', NULL, 'Invoice:INV000087, Name:10 inch pp filter, Qty:1 X 120, Total:120\n\nName:10 Inch CTO Filter, Qty:1 X 250, Total:250\n\nName:10 Inch GAC Filter, Qty:1 X 250, Total:250\n\nName:Transport, Qty:1 X 300, Total:300\n', NULL, NULL, NULL, '2024-10-23', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 22:17:11', '2024-11-19 22:17:11'),
(627, '01', 'CHA000089', 'INV000089', '01SV000089', '2024-10-28', 161, 'Sales Account', 'SV', 14800.00, 'Dr', NULL, 'Invoice:INV000089, Name:RO-105, Qty:1 X 14800, Total:14800\n', NULL, NULL, NULL, '2024-10-28', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 22:30:51', '2024-11-19 22:30:51'),
(628, '01', 'CHA000089', 'INV000089', '01SV000089', '2024-10-28', 14, 'BD Unani & Ayurbedic', 'SV', 14800.00, 'Cr', NULL, 'Invoice:INV000089, Name:RO-105, Qty:1 X 14800, Total:14800\n', NULL, NULL, NULL, '2024-10-28', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 22:30:51', '2024-11-19 22:30:51'),
(629, '01', 'CHA000089', 'INV000089', '01SV000089', '2024-10-28', 161, 'Cash', 'SV', 14800.00, 'Cr', 'Cash in hand', 'Invoice:INV000089, Cash Received From: BD Unani & Ayurbedic, Through Cash Received Amount:14,800.00 TK \n', '0', NULL, NULL, '2024-10-28', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 22:30:51', '2024-11-19 22:30:51'),
(630, '01', 'CHA000089', 'INV000089', '01SV000089', '2024-10-28', 11, 'BD Unani & Ayurbedic', 'SV', 14800.00, 'Dr', 'Cash in hand', 'Invoice:INV000089, Cash Received From: BD Unani & Ayurbedic, Through Cash Received Amount:14,800.00 TK \n', '0', NULL, NULL, '2024-10-28', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 22:30:51', '2024-11-19 22:30:51'),
(631, '01', 'CHA000090', 'INV000090', '01SV000090', '2024-11-01', 135, 'Sales Account', 'SV', 4400.00, 'Dr', NULL, 'Invoice:INV000090, Name:10 Inch CTO Filter, Qty:1 X 250, Total:250\n\nName:10 Inch GAC Filter, Qty:1 X 250, Total:250\n\nName:Water Storage Tank, Qty:1 X 3700, Total:3700\n\nName:Transport, Qty:1 X 200, Total:200\n', NULL, NULL, NULL, '2024-11-01', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 22:32:44', '2024-11-19 22:32:44'),
(632, '01', 'CHA000090', 'INV000090', '01SV000090', '2024-11-01', 14, 'Md Hossain Ahmed', 'SV', 4400.00, 'Cr', NULL, 'Invoice:INV000090, Name:10 Inch CTO Filter, Qty:1 X 250, Total:250\n\nName:10 Inch GAC Filter, Qty:1 X 250, Total:250\n\nName:Water Storage Tank, Qty:1 X 3700, Total:3700\n\nName:Transport, Qty:1 X 200, Total:200\n', NULL, NULL, NULL, '2024-11-01', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 22:32:44', '2024-11-19 22:32:44'),
(633, '01', 'CHA000090', 'INV000090', '01SV000090', '2024-11-01', 135, 'Cash', 'SV', 4400.00, 'Cr', 'Cash in hand', 'Invoice:INV000090, Cash Received From: Md Hossain Ahmed, Through Cash Received Amount:4,400.00 TK \n', '0', NULL, NULL, '2024-11-01', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 22:32:44', '2024-11-19 22:32:44'),
(634, '01', 'CHA000090', 'INV000090', '01SV000090', '2024-11-01', 11, 'Md Hossain Ahmed', 'SV', 4400.00, 'Dr', 'Cash in hand', 'Invoice:INV000090, Cash Received From: Md Hossain Ahmed, Through Cash Received Amount:4,400.00 TK \n', '0', NULL, NULL, '2024-11-01', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 22:32:44', '2024-11-19 22:32:44'),
(635, '01', 'CHA000091', 'INV000091', '01SV000091', '2024-11-03', 162, 'Sales Account', 'SV', 500.00, 'Dr', NULL, 'Invoice:INV000091, Name:Pay service, Qty:1 X 500, Total:500\n', NULL, NULL, NULL, '2024-11-03', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 22:36:11', '2024-11-19 22:36:11'),
(636, '01', 'CHA000091', 'INV000091', '01SV000091', '2024-11-03', 14, 'MD Jahid Hasan', 'SV', 500.00, 'Cr', NULL, 'Invoice:INV000091, Name:Pay service, Qty:1 X 500, Total:500\n', NULL, NULL, NULL, '2024-11-03', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 22:36:11', '2024-11-19 22:36:11'),
(637, '01', 'CHA000091', 'INV000091', '01SV000091', '2024-11-03', 162, 'Cash', 'SV', 500.00, 'Cr', 'Cash in hand', 'Invoice:INV000091, Cash Received From: MD Jahid Hasan, Through Cash Received Amount:500.00 TK \n', '0', NULL, NULL, '2024-11-03', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 22:36:11', '2024-11-19 22:36:11'),
(638, '01', 'CHA000091', 'INV000091', '01SV000091', '2024-11-03', 11, 'MD Jahid Hasan', 'SV', 500.00, 'Dr', 'Cash in hand', 'Invoice:INV000091, Cash Received From: MD Jahid Hasan, Through Cash Received Amount:500.00 TK \n', '0', NULL, NULL, '2024-11-03', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 22:36:11', '2024-11-19 22:36:11'),
(639, '01', 'CHA000092', 'INV000092', '01SV000092', '2024-11-03', 163, 'Sales Account', 'SV', 400.00, 'Dr', NULL, 'Invoice:INV000092, Name:Pay service, Qty:1 X 400, Total:400\n', NULL, NULL, NULL, '2024-11-03', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 22:51:05', '2024-11-19 22:51:05'),
(640, '01', 'CHA000092', 'INV000092', '01SV000092', '2024-11-03', 14, 'MD Soleman', 'SV', 400.00, 'Cr', NULL, 'Invoice:INV000092, Name:Pay service, Qty:1 X 400, Total:400\n', NULL, NULL, NULL, '2024-11-03', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 22:51:05', '2024-11-19 22:51:05'),
(641, '01', 'CHA000092', 'INV000092', '01SV000092', '2024-11-03', 163, 'Cash', 'SV', 400.00, 'Cr', 'Cash in hand', 'Invoice:INV000092, Cash Received From: MD Soleman, Through Cash Received Amount:400.00 TK \n', '0', NULL, NULL, '2024-11-03', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 22:51:05', '2024-11-19 22:51:05'),
(642, '01', 'CHA000092', 'INV000092', '01SV000092', '2024-11-03', 11, 'MD Soleman', 'SV', 400.00, 'Dr', 'Cash in hand', 'Invoice:INV000092, Cash Received From: MD Soleman, Through Cash Received Amount:400.00 TK \n', '0', NULL, NULL, '2024-11-03', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 22:51:05', '2024-11-19 22:51:05'),
(643, '01', 'CHA000093', 'INV000093', '01SV000093', '2024-11-04', 164, 'Sales Account', 'SV', 500.00, 'Dr', NULL, 'Invoice:INV000093, Name:Pay service, Qty:1 X 500, Total:500\n', NULL, NULL, NULL, '2024-11-04', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 22:53:35', '2024-11-19 22:53:35'),
(644, '01', 'CHA000093', 'INV000093', '01SV000093', '2024-11-04', 14, 'MD Rakib Ali', 'SV', 500.00, 'Cr', NULL, 'Invoice:INV000093, Name:Pay service, Qty:1 X 500, Total:500\n', NULL, NULL, NULL, '2024-11-04', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 22:53:35', '2024-11-19 22:53:35'),
(645, '01', 'CHA000093', 'INV000093', '01SV000093', '2024-11-04', 164, 'Cash', 'SV', 500.00, 'Cr', 'Cash in hand', 'Invoice:INV000093, Cash Received From: MD Rakib Ali, Through Cash Received Amount:500.00 TK \n', '0', NULL, NULL, '2024-11-04', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 22:53:35', '2024-11-19 22:53:35'),
(646, '01', 'CHA000093', 'INV000093', '01SV000093', '2024-11-04', 11, 'MD Rakib Ali', 'SV', 500.00, 'Dr', 'Cash in hand', 'Invoice:INV000093, Cash Received From: MD Rakib Ali, Through Cash Received Amount:500.00 TK \n', '0', NULL, NULL, '2024-11-04', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 22:53:35', '2024-11-19 22:53:35'),
(647, '01', 'CHA000094', 'INV000094', '01SV000094', '2024-11-10', 165, 'Sales Account', 'SV', 10400.00, 'Dr', NULL, 'Invoice:INV000094, Name:RO-105, Qty:1 X 10000, Total:10000\n\nName:Inline Slim Alkaline Filter Heron, Qty:1 X 400, Total:400\n', NULL, NULL, NULL, '2024-11-10', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 23:01:12', '2024-11-19 23:01:12'),
(648, '01', 'CHA000094', 'INV000094', '01SV000094', '2024-11-10', 14, 'Mr Habib', 'SV', 10400.00, 'Cr', NULL, 'Invoice:INV000094, Name:RO-105, Qty:1 X 10000, Total:10000\n\nName:Inline Slim Alkaline Filter Heron, Qty:1 X 400, Total:400\n', NULL, NULL, NULL, '2024-11-10', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 23:01:12', '2024-11-19 23:01:12'),
(649, '01', 'CHA000094', 'INV000094', '01SV000094', '2024-11-10', 165, 'Cash', 'SV', 10400.00, 'Cr', 'Cash in hand', 'Invoice:INV000094, Cash Received From: Mr Habib, Through Cash Received Amount:10,400.00 TK \n', '0', NULL, NULL, '2024-11-10', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 23:01:12', '2024-11-19 23:01:12'),
(650, '01', 'CHA000094', 'INV000094', '01SV000094', '2024-11-10', 11, 'Mr Habib', 'SV', 10400.00, 'Dr', 'Cash in hand', 'Invoice:INV000094, Cash Received From: Mr Habib, Through Cash Received Amount:10,400.00 TK \n', '0', NULL, NULL, '2024-11-10', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 23:01:12', '2024-11-19 23:01:12'),
(651, '01', 'CHA000095', 'INV000095', '01SV000095', '2024-11-14', 165, 'Sales Account', 'SV', 400.00, 'Dr', NULL, 'Invoice:INV000095, Name:Pay service, Qty:1 X 300, Total:300\n\nName:6mm Pipe., Qty:5 X 20, Total:100\n', NULL, NULL, NULL, '2024-11-14', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 23:02:58', '2024-11-19 23:02:58'),
(652, '01', 'CHA000095', 'INV000095', '01SV000095', '2024-11-14', 14, 'Mr Habib', 'SV', 400.00, 'Cr', NULL, 'Invoice:INV000095, Name:Pay service, Qty:1 X 300, Total:300\n\nName:6mm Pipe., Qty:5 X 20, Total:100\n', NULL, NULL, NULL, '2024-11-14', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 23:02:58', '2024-11-19 23:02:58'),
(653, '01', 'CHA000095', 'INV000095', '01SV000095', '2024-11-14', 165, 'Cash', 'SV', 400.00, 'Cr', 'Cash in hand', 'Invoice:INV000095, Cash Received From: Mr Habib, Through Cash Received Amount:400.00 TK \n', '0', NULL, NULL, '2024-11-14', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 23:02:58', '2024-11-19 23:02:58'),
(654, '01', 'CHA000095', 'INV000095', '01SV000095', '2024-11-14', 11, 'Mr Habib', 'SV', 400.00, 'Dr', 'Cash in hand', 'Invoice:INV000095, Cash Received From: Mr Habib, Through Cash Received Amount:400.00 TK \n', '0', NULL, NULL, '2024-11-14', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 23:02:58', '2024-11-19 23:02:58'),
(655, '01', 'CHA000096', 'INV000096', '01SV000096', '2024-11-18', 166, 'Sales Account', 'SV', 300.00, 'Dr', NULL, 'Invoice:INV000096, Name:Pay service, Qty:1 X 300, Total:300\n', NULL, NULL, NULL, '2024-11-18', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 23:06:25', '2024-11-19 23:06:25'),
(656, '01', 'CHA000096', 'INV000096', '01SV000096', '2024-11-18', 14, 'Shadat Hasan', 'SV', 300.00, 'Cr', NULL, 'Invoice:INV000096, Name:Pay service, Qty:1 X 300, Total:300\n', NULL, NULL, NULL, '2024-11-18', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 23:06:25', '2024-11-19 23:06:25'),
(657, '01', 'CHA000096', 'INV000096', '01SV000096', '2024-11-18', 166, 'Cash', 'SV', 300.00, 'Cr', 'Cash in hand', 'Invoice:INV000096, Cash Received From: Shadat Hasan, Through Cash Received Amount:300.00 TK \n', '0', NULL, NULL, '2024-11-18', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 23:06:25', '2024-11-19 23:06:25'),
(658, '01', 'CHA000096', 'INV000096', '01SV000096', '2024-11-18', 11, 'Shadat Hasan', 'SV', 300.00, 'Dr', 'Cash in hand', 'Invoice:INV000096, Cash Received From: Shadat Hasan, Through Cash Received Amount:300.00 TK \n', '0', NULL, NULL, '2024-11-18', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 23:06:25', '2024-11-19 23:06:25'),
(659, '01', 'CHA000097', 'INV000097', '01SV000097', '2024-11-18', 143, 'Sales Account', 'SV', 700.00, 'Dr', NULL, 'Invoice:INV000097, Name:10 inch pp filter, Qty:1 X 100, Total:100\n\nName:10 Inch CTO Filter, Qty:1 X 250, Total:250\n\nName:10 Inch GAC Filter, Qty:1 X 250, Total:250\n\nName:Pay service, Qty:1 X 100, Total:100\n', NULL, NULL, NULL, '2024-11-18', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 23:12:42', '2024-11-19 23:12:42'),
(660, '01', 'CHA000097', 'INV000097', '01SV000097', '2024-11-18', 14, 'Md Alomgir Sir.', 'SV', 700.00, 'Cr', NULL, 'Invoice:INV000097, Name:10 inch pp filter, Qty:1 X 100, Total:100\n\nName:10 Inch CTO Filter, Qty:1 X 250, Total:250\n\nName:10 Inch GAC Filter, Qty:1 X 250, Total:250\n\nName:Pay service, Qty:1 X 100, Total:100\n', NULL, NULL, NULL, '2024-11-18', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 23:12:42', '2024-11-19 23:12:42'),
(661, '01', 'CHA000097', 'INV000097', '01SV000097', '2024-11-18', 143, 'Cash', 'SV', 700.00, 'Cr', 'Cash in hand', 'Invoice:INV000097, Cash Received From: Md Alomgir Sir., Through Cash Received Amount:700.00 TK \n', '0', NULL, NULL, '2024-11-18', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 23:12:42', '2024-11-19 23:12:42'),
(662, '01', 'CHA000097', 'INV000097', '01SV000097', '2024-11-18', 11, 'Md Alomgir Sir.', 'SV', 700.00, 'Dr', 'Cash in hand', 'Invoice:INV000097, Cash Received From: Md Alomgir Sir., Through Cash Received Amount:700.00 TK \n', '0', NULL, NULL, '2024-11-18', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-19 23:12:42', '2024-11-19 23:12:42'),
(663, '01', 'CHA000098', 'INV000098', '01SV000098', '2024-11-20', 108, 'Sales Account', 'SV', 10800.00, 'Dr', NULL, 'Invoice:INV000098, Name:RO-105, Qty:1 X 10000, Total:10000\n\nName:Outside Product, Qty:1 X 500, Total:500\n\nName:Conveyance, Qty:1 X 300, Total:300\n', NULL, NULL, NULL, '2024-11-20', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-20 20:49:52', '2024-11-20 20:49:52'),
(664, '01', 'CHA000098', 'INV000098', '01SV000098', '2024-11-20', 14, 'Customer 1', 'SV', 10800.00, 'Cr', NULL, 'Invoice:INV000098, Name:RO-105, Qty:1 X 10000, Total:10000\n\nName:Outside Product, Qty:1 X 500, Total:500\n\nName:Conveyance, Qty:1 X 300, Total:300\n', NULL, NULL, NULL, '2024-11-20', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-20 20:49:52', '2024-11-20 20:49:52'),
(665, '01', 'CHA000098', 'INV000098', '01SV000098', '2024-11-20', 108, 'Cash', 'SV', 10800.00, 'Cr', 'Cash in hand', 'Invoice:INV000098, Cash Received From: Customer 1, Through Cash Received Amount:10,800.00 TK done\n', '0', NULL, NULL, '2024-11-20', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-20 20:49:52', '2024-11-20 20:49:52'),
(666, '01', 'CHA000098', 'INV000098', '01SV000098', '2024-11-20', 11, 'Customer 1', 'SV', 10800.00, 'Dr', 'Cash in hand', 'Invoice:INV000098, Cash Received From: Customer 1, Through Cash Received Amount:10,800.00 TK done\n', '0', NULL, NULL, '2024-11-20', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-20 20:49:52', '2024-11-20 20:49:52'),
(667, '01', 'CHA000099', 'INV000099', '01SV000099', '2024-11-19', 129, 'Sales Account', 'SV', 900.00, 'Dr', NULL, 'Invoice:INV000099, Name:10 inch pp filter, Qty:1 X 100, Total:100\n\nName:10 Inch CTO Filter, Qty:1 X 250, Total:250\n\nName:10 Inch GAC Filter, Qty:1 X 250, Total:250\n\nName:Pay service, Qty:1 X 300, Total:300\n', NULL, NULL, NULL, '2024-11-19', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-23 22:28:17', '2024-11-23 22:28:17'),
(668, '01', 'CHA000099', 'INV000099', '01SV000099', '2024-11-19', 14, 'Shahanaz Bristy', 'SV', 900.00, 'Cr', NULL, 'Invoice:INV000099, Name:10 inch pp filter, Qty:1 X 100, Total:100\n\nName:10 Inch CTO Filter, Qty:1 X 250, Total:250\n\nName:10 Inch GAC Filter, Qty:1 X 250, Total:250\n\nName:Pay service, Qty:1 X 300, Total:300\n', NULL, NULL, NULL, '2024-11-19', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-23 22:28:17', '2024-11-23 22:28:17'),
(669, '01', 'CHA000099', 'INV000099', '01SV000099', '2024-11-19', 129, 'Cash', 'SV', 900.00, 'Cr', 'Cash in hand', 'Invoice:INV000099, Cash Received From: Shahanaz Bristy, Through Cash Received Amount:900.00 TK \n', '0', NULL, NULL, '2024-11-19', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-23 22:28:17', '2024-11-23 22:28:17'),
(670, '01', 'CHA000099', 'INV000099', '01SV000099', '2024-11-19', 11, 'Shahanaz Bristy', 'SV', 900.00, 'Dr', 'Cash in hand', 'Invoice:INV000099, Cash Received From: Shahanaz Bristy, Through Cash Received Amount:900.00 TK \n', '0', NULL, NULL, '2024-11-19', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-23 22:28:17', '2024-11-23 22:28:17'),
(671, '01', 'CHA000100', 'INV000100', '01SV000100', '2024-11-20', 167, 'Sales Account', 'SV', 700.00, 'Dr', NULL, 'Invoice:INV000100, Name:10 inch pp filter, Qty:1 X 100, Total:100\n\nName:10 Inch CTO Filter, Qty:1 X 250, Total:250\n\nName:10 Inch GAC Filter, Qty:1 X 250, Total:250\n\nName:Transport, Qty:1 X 100, Total:100\n', NULL, NULL, NULL, '2024-11-20', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-23 22:32:31', '2024-11-23 22:32:31'),
(672, '01', 'CHA000100', 'INV000100', '01SV000100', '2024-11-20', 14, 'MD limon', 'SV', 700.00, 'Cr', NULL, 'Invoice:INV000100, Name:10 inch pp filter, Qty:1 X 100, Total:100\n\nName:10 Inch CTO Filter, Qty:1 X 250, Total:250\n\nName:10 Inch GAC Filter, Qty:1 X 250, Total:250\n\nName:Transport, Qty:1 X 100, Total:100\n', NULL, NULL, NULL, '2024-11-20', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-23 22:32:31', '2024-11-23 22:32:31'),
(673, '01', 'CHA000100', 'INV000100', '01SV000100', '2024-11-20', 167, 'Cash', 'SV', 700.00, 'Cr', 'Cash in hand', 'Invoice:INV000100, Cash Received From: MD limon, Through Cash Received Amount:700.00 TK \n', '0', NULL, NULL, '2024-11-20', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-23 22:32:31', '2024-11-23 22:32:31'),
(674, '01', 'CHA000100', 'INV000100', '01SV000100', '2024-11-20', 11, 'MD limon', 'SV', 700.00, 'Dr', 'Cash in hand', 'Invoice:INV000100, Cash Received From: MD limon, Through Cash Received Amount:700.00 TK \n', '0', NULL, NULL, '2024-11-20', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-23 22:32:31', '2024-11-23 22:32:31'),
(675, '01', 'CHA000101', 'INV000101', '01SV000101', '2024-11-23', 137, 'Sales Account', 'SV', 800.00, 'Dr', NULL, 'Invoice:INV000101, Name:10 inch pp filter, Qty:1 X 100, Total:100\n\nName:10 Inch CTO Filter, Qty:1 X 250, Total:250\n\nName:10 Inch GAC Filter, Qty:1 X 250, Total:250\n\nName:Transport, Qty:1 X 200, Total:200\n', NULL, NULL, NULL, '2024-11-23', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-23 22:34:10', '2024-11-23 22:34:10'),
(676, '01', 'CHA000101', 'INV000101', '01SV000101', '2024-11-23', 14, 'Shakwat Rahim  Khan.', 'SV', 800.00, 'Cr', NULL, 'Invoice:INV000101, Name:10 inch pp filter, Qty:1 X 100, Total:100\n\nName:10 Inch CTO Filter, Qty:1 X 250, Total:250\n\nName:10 Inch GAC Filter, Qty:1 X 250, Total:250\n\nName:Transport, Qty:1 X 200, Total:200\n', NULL, NULL, NULL, '2024-11-23', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-23 22:34:10', '2024-11-23 22:34:10'),
(677, '01', 'CHA000101', 'INV000101', '01SV000101', '2024-11-23', 137, 'Cash', 'SV', 800.00, 'Cr', 'Cash in hand', 'Invoice:INV000101, Cash Received From: Shakwat Rahim  Khan., Through Cash Received Amount:800.00 TK \n', '0', NULL, NULL, '2024-11-23', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-23 22:34:10', '2024-11-23 22:34:10'),
(678, '01', 'CHA000101', 'INV000101', '01SV000101', '2024-11-23', 11, 'Shakwat Rahim  Khan.', 'SV', 800.00, 'Dr', 'Cash in hand', 'Invoice:INV000101, Cash Received From: Shakwat Rahim  Khan., Through Cash Received Amount:800.00 TK \n', '0', NULL, NULL, '2024-11-23', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-23 22:34:10', '2024-11-23 22:34:10'),
(679, '01', 'CHA000088', 'INV000088', '01SV000088', '2024-10-27', 160, 'Sales Account', 'SV', 800.00, 'Dr', NULL, 'Invoice:INV000088, Name:10 inch pp filter, Qty:4.00 X 100.00, , Total:400\n\nName:Pay service, Qty:1.00 X 400.00, , Total:400\n', NULL, NULL, NULL, '2024-10-27', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-26 20:07:42', '2024-11-26 20:07:42'),
(680, '01', 'CHA000088', 'INV000088', '01SV000088', '2024-10-27', 14, 'Muza Wasin', 'SV', 800.00, 'Cr', NULL, 'Invoice:INV000088, Name:10 inch pp filter, Qty:4.00 X 100.00, , Total:400\n\nName:Pay service, Qty:1.00 X 400.00, , Total:400\n', NULL, NULL, NULL, '2024-10-27', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-26 20:07:42', '2024-11-26 20:07:42'),
(681, '01', 'CHA000088', 'INV000088', '01SV000088', '2024-10-27', 160, 'Cash', 'SV', 800.00, 'Cr', 'Cash in hand', 'Invoice:INV000088, Cash Received From: Muza Wasin, Through Cash Received Amount:800.00 TK \n', NULL, NULL, NULL, '2024-10-27', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-26 20:07:42', '2024-11-26 20:07:42'),
(682, '01', 'CHA000088', 'INV000088', '01SV000088', '2024-10-27', 11, 'Muza Wasin', 'SV', 800.00, 'Dr', 'Cash in hand', 'Invoice:INV000088, Cash Received From: Muza Wasin, Through Cash Received Amount:800.00 TK \n', NULL, NULL, NULL, '2024-10-27', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-26 20:07:42', '2024-11-26 20:07:42'),
(683, '01', 'CHA000102', 'INV000102', '01SV000102', '2024-11-23', 168, 'Sales Account', 'SV', 700.00, 'Dr', NULL, 'Invoice:INV000102, Name:10 inch pp filter, Qty:1 X 100, Total:100\n\nName:10 Inch CTO Filter, Qty:1 X 250, Total:250\n\nName:10 Inch GAC Filter, Qty:1 X 250, Total:250\n\nName:10 Inch Housing Wrench White, Qty:1 X 100, Total:100\n', NULL, NULL, NULL, '2024-11-23', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-26 22:23:41', '2024-11-26 22:23:41'),
(684, '01', 'CHA000102', 'INV000102', '01SV000102', '2024-11-23', 14, 'Md Junayed Hossain', 'SV', 700.00, 'Cr', NULL, 'Invoice:INV000102, Name:10 inch pp filter, Qty:1 X 100, Total:100\n\nName:10 Inch CTO Filter, Qty:1 X 250, Total:250\n\nName:10 Inch GAC Filter, Qty:1 X 250, Total:250\n\nName:10 Inch Housing Wrench White, Qty:1 X 100, Total:100\n', NULL, NULL, NULL, '2024-11-23', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-26 22:23:41', '2024-11-26 22:23:41'),
(685, '01', 'CHA000102', 'INV000102', '01SV000102', '2024-11-23', 168, 'Cash', 'SV', 700.00, 'Cr', 'Cash in hand', 'Invoice:INV000102, Cash Received From: Md Junayed Hossain, Through Cash Received Amount:700.00 TK \n', '0', NULL, NULL, '2024-11-23', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-26 22:23:41', '2024-11-26 22:23:41'),
(686, '01', 'CHA000102', 'INV000102', '01SV000102', '2024-11-23', 11, 'Md Junayed Hossain', 'SV', 700.00, 'Dr', 'Cash in hand', 'Invoice:INV000102, Cash Received From: Md Junayed Hossain, Through Cash Received Amount:700.00 TK \n', '0', NULL, NULL, '2024-11-23', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-26 22:23:41', '2024-11-26 22:23:41'),
(687, '01', NULL, 'PUR000022', '01PV000022', '2024-11-25', 13, 'ABM engineering', 'PV', 86540.00, 'Dr', NULL, 'Invoice No:PUR000022, Name:Osmo Smart, Qty:10 X 8654, Total:86540\n', NULL, NULL, NULL, '2024-11-25', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-27 22:05:59', '2024-11-27 22:05:59'),
(688, '01', NULL, 'PUR000022', '01PV000022', '2024-11-25', 112, 'Purchase Account', 'PV', 86540.00, 'Cr', NULL, 'Invoice No:PUR000022, Name:Osmo Smart, Qty:10 X 8654, Total:86540\n', NULL, NULL, NULL, '2024-11-25', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-27 22:05:59', '2024-11-27 22:05:59'),
(689, '01', NULL, 'PUR000022', '01PV000022', '2024-11-25', 112, 'Cash', 'PV', 86540.00, 'Dr', 'Cash in hand', 'Invoice No:PUR000022, Cash Payment To: ABM engineering, Through Cash, Payment Amount:86,540.00 TK \n', '0', NULL, NULL, '2024-11-25', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-27 22:05:59', '2024-11-27 22:05:59'),
(690, '01', NULL, 'PUR000022', '01PV000022', '2024-11-25', 11, 'ABM engineering', 'PV', 86540.00, 'Cr', 'Cash in hand', 'Invoice No:PUR000022, Cash Payment To: ABM engineering, Through Cash, Payment Amount:86,540.00 TK \n', '0', NULL, NULL, '2024-11-25', 'Admin', NULL, NULL, 0, 'Admin', NULL, '2024-11-27 22:05:59', '2024-11-27 22:05:59');

-- --------------------------------------------------------

--
-- Table structure for table `genrate_payslip_options`
--

CREATE TABLE `genrate_payslip_options` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;

-- --------------------------------------------------------

--
-- Table structure for table `holidays`
--

CREATE TABLE `holidays` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `date` date NOT NULL,
  `end_date` date NOT NULL,
  `occasion` text NOT NULL,
  `created_by` int(11) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `holidays`
--

INSERT INTO `holidays` (`id`, `date`, `end_date`, `occasion`, `created_by`, `created_at`, `updated_at`) VALUES
(6, '2024-01-05', '2024-01-05', 'Christmas Day', 1, '2023-12-18 23:45:52', '2024-01-14 02:54:35');

-- --------------------------------------------------------

--
-- Table structure for table `incomes`
--

CREATE TABLE `incomes` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `employee_id` int(11) NOT NULL,
  `income_head` int(11) NOT NULL,
  `amount` double(20,2) NOT NULL DEFAULT 0.00,
  `percentage` decimal(5,2) DEFAULT 0.00,
  `type` tinyint(4) DEFAULT 1,
  `created_by` varchar(120) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `income_heads`
--

CREATE TABLE `income_heads` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` tinyint(4) DEFAULT 1,
  `created_by` varchar(125) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `income_heads`
--

INSERT INTO `income_heads` (`id`, `name`, `status`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 'House Rent', 1, 'Demo', '2023-12-17 01:46:11', '2023-12-17 01:46:11'),
(2, 'Medical', 1, 'Demo', '2023-12-17 01:46:40', '2023-12-17 01:46:40'),
(3, 'P/F', 1, 'Demo', '2023-12-17 01:52:22', '2023-12-17 01:55:52'),
(4, 'Others', 1, 'Demo', '2023-12-17 01:56:38', '2023-12-17 02:02:37');

-- --------------------------------------------------------

--
-- Table structure for table `invoiceno`
--

CREATE TABLE `invoiceno` (
  `voucher_no` int(11) DEFAULT NULL,
  `order_no` int(11) DEFAULT NULL,
  `invoice_no_id` int(11) NOT NULL,
  `delivery_challan_no` int(11) DEFAULT NULL,
  `sales_no` int(11) DEFAULT NULL,
  `purchase_no` int(11) DEFAULT NULL,
  `cr_voucher_no` int(11) DEFAULT NULL,
  `cp_voucher_no` int(11) DEFAULT NULL,
  `quotation_no` int(11) DEFAULT NULL,
  `transfer_no` int(11) DEFAULT NULL,
  `batch_no` int(11) DEFAULT NULL,
  `branch_id` int(11) DEFAULT NULL,
  `money_receipt_no` int(11) DEFAULT NULL,
  `delivery_order_no` int(11) DEFAULT NULL,
  `white_slip_no` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `invoiceno`
--

INSERT INTO `invoiceno` (`voucher_no`, `order_no`, `invoice_no_id`, `delivery_challan_no`, `sales_no`, `purchase_no`, `cr_voucher_no`, `cp_voucher_no`, `quotation_no`, `transfer_no`, `batch_no`, `branch_id`, `money_receipt_no`, `delivery_order_no`, `white_slip_no`) VALUES
(103, 2, 1, 103, 103, 23, 23, 1, 1, 1, 1, 1, 1, 1, 1);

-- --------------------------------------------------------

--
-- Table structure for table `late_times`
--

CREATE TABLE `late_times` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `late_time` time DEFAULT NULL,
  `created_by` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `late_times`
--

INSERT INTO `late_times` (`id`, `late_time`, `created_by`, `created_at`, `updated_at`) VALUES
(1, '09:37:00', 'Demo', '2024-01-11 00:25:57', '2024-01-14 00:29:20');

-- --------------------------------------------------------

--
-- Table structure for table `loans`
--

CREATE TABLE `loans` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `employee_id` int(11) NOT NULL,
  `loan_option` int(11) NOT NULL,
  `title` varchar(255) DEFAULT NULL,
  `amount` double(20,2) NOT NULL DEFAULT 0.00,
  `percentage` decimal(5,2) DEFAULT 0.00,
  `type` tinyint(4) DEFAULT 1,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `reason` varchar(255) NOT NULL,
  `created_by` int(11) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;

--
-- Dumping data for table `loans`
--

INSERT INTO `loans` (`id`, `employee_id`, `loan_option`, `title`, `amount`, `percentage`, `type`, `start_date`, `end_date`, `reason`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 'Allowance Title', 3000.00, 10.00, 2, '2023-11-01', '2023-12-31', 'Loan Reason', 1, '2023-12-16 23:58:07', '2023-12-16 23:58:07');

-- --------------------------------------------------------

--
-- Table structure for table `loan_options`
--

CREATE TABLE `loan_options` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `status` tinyint(4) DEFAULT 1,
  `created_by` int(11) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;

--
-- Dumping data for table `loan_options`
--

INSERT INTO `loan_options` (`id`, `name`, `status`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 'Loan 1', 1, 1, '2023-07-13 07:21:21', '2023-07-13 07:21:34'),
(2, 'Loan 3', 1, 1, '2023-07-13 07:21:30', '2023-12-17 04:40:34');

-- --------------------------------------------------------

--
-- Table structure for table `meetings`
--

CREATE TABLE `meetings` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `branch_id` int(11) DEFAULT NULL,
  `department_id` longtext DEFAULT NULL,
  `employee_id` longtext DEFAULT NULL,
  `title` varchar(191) NOT NULL,
  `date` date NOT NULL,
  `time` time NOT NULL,
  `note` text DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `migrations`
--

CREATE TABLE `migrations` (
  `id` int(10) UNSIGNED NOT NULL,
  `migration` varchar(191) NOT NULL,
  `batch` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `migrations`
--

INSERT INTO `migrations` (`id`, `migration`, `batch`) VALUES
(1, '2014_10_12_000000_create_users_table', 1),
(2, '2014_10_12_100000_create_password_resets_table', 1),
(3, '2019_08_19_000000_create_failed_jobs_table', 1),
(4, '2019_12_14_000001_create_personal_access_tokens_table', 1),
(5, '2023_05_28_090500_add_login_fields_to_users_table', 1),
(6, '2023_06_11_075700_create_permission_tables', 1),
(7, '2023_06_12_013333_add_profile_photo_path_column_to_users_table', 1),
(8, '2024_05_28_185132_create_notifications_table', 2);

-- --------------------------------------------------------

--
-- Table structure for table `model_has_permissions`
--

CREATE TABLE `model_has_permissions` (
  `permission_id` bigint(20) UNSIGNED NOT NULL,
  `model_type` varchar(191) NOT NULL,
  `model_id` bigint(20) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `model_has_roles`
--

CREATE TABLE `model_has_roles` (
  `role_id` bigint(20) UNSIGNED NOT NULL,
  `model_type` varchar(191) NOT NULL,
  `model_id` bigint(20) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `model_has_roles`
--

INSERT INTO `model_has_roles` (`role_id`, `model_type`, `model_id`) VALUES
(1, 'App\\Models\\User', 1),
(1, 'App\\Models\\User', 27),
(1, 'App\\Models\\User', 32),
(2, 'App\\Models\\User', 29),
(2, 'App\\Models\\User', 31),
(2, 'App\\Models\\User', 34),
(3, 'App\\Models\\User', 42),
(3, 'App\\Models\\User', 43),
(7, 'App\\Models\\User', 33),
(8, 'App\\Models\\User', 38),
(9, 'App\\Models\\User', 41),
(10, 'App\\Models\\User', 39),
(11, 'App\\Models\\User', 35),
(12, 'App\\Models\\User', 30);

-- --------------------------------------------------------

--
-- Table structure for table `monthly_salaries`
--

CREATE TABLE `monthly_salaries` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `employee_id` bigint(20) NOT NULL,
  `branch_id` bigint(20) DEFAULT NULL,
  `generate_date` timestamp NULL DEFAULT NULL,
  `salary_month` varchar(191) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `basic_salary` decimal(11,2) NOT NULL DEFAULT 0.00,
  `income` decimal(11,2) NOT NULL DEFAULT 0.00,
  `deduction` decimal(11,2) NOT NULL DEFAULT 0.00,
  `net_payble` decimal(11,2) NOT NULL DEFAULT 0.00,
  `status` int(11) NOT NULL,
  `created_by` varchar(120) NOT NULL,
  `approved_by` varchar(120) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `monthly_salaries`
--

INSERT INTO `monthly_salaries` (`id`, `employee_id`, `branch_id`, `generate_date`, `salary_month`, `basic_salary`, `income`, `deduction`, `net_payble`, `status`, `created_by`, `approved_by`, `created_at`, `updated_at`) VALUES
(1, 38, NULL, '2024-03-20 18:00:00', '2024-03', 50000.00, 0.00, 0.00, 0.00, 0, '1', NULL, '2024-03-21 02:28:16', '2024-03-21 02:28:16'),
(2, 39, NULL, '2024-03-20 18:00:00', '2024-03', 55555.00, 0.00, 0.00, 0.00, 0, '1', NULL, '2024-03-21 02:28:16', '2024-03-21 02:28:16'),
(3, 40, NULL, '2024-03-20 18:00:00', '2024-03', 50000.00, 0.00, 0.00, 0.00, 0, '1', NULL, '2024-03-21 02:28:16', '2024-03-21 02:28:16'),
(4, 41, NULL, '2024-03-20 18:00:00', '2024-03', 40000.00, 0.00, 0.00, 0.00, 0, '1', NULL, '2024-03-21 02:28:16', '2024-03-21 02:28:16'),
(5, 38, NULL, '2024-03-20 18:00:00', '2024-02', 50000.00, 0.00, 0.00, 0.00, 0, '1', NULL, '2024-03-21 02:39:32', '2024-03-21 02:39:32'),
(6, 39, NULL, '2024-03-20 18:00:00', '2024-02', 55555.00, 0.00, 0.00, 0.00, 0, '1', NULL, '2024-03-21 02:39:32', '2024-03-21 02:39:32'),
(7, 40, NULL, '2024-03-20 18:00:00', '2024-02', 50000.00, 0.00, 0.00, 0.00, 0, '1', NULL, '2024-03-21 02:39:32', '2024-03-21 02:39:32'),
(8, 41, NULL, '2024-03-20 18:00:00', '2024-02', 40000.00, 0.00, 0.00, 0.00, 0, '1', NULL, '2024-03-21 02:39:32', '2024-03-21 02:39:32');

-- --------------------------------------------------------

--
-- Table structure for table `monthly_salary_details`
--

CREATE TABLE `monthly_salary_details` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `monthly_salary_id` bigint(20) NOT NULL,
  `head_id` bigint(20) NOT NULL,
  `head_name` varchar(120) NOT NULL,
  `head_type` varchar(120) NOT NULL,
  `amount` decimal(11,2) NOT NULL DEFAULT 0.00,
  `created_by` varchar(120) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `monthly_salary_details`
--

INSERT INTO `monthly_salary_details` (`id`, `monthly_salary_id`, `head_id`, `head_name`, `head_type`, `amount`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 'House Rent', 'Income', 20000.00, 'Demo', '2023-12-23 23:34:40', '2023-12-23 23:34:40'),
(2, 1, 1, 'TAX', 'Deduction', 2000.00, 'Demo', '2023-12-23 23:34:40', '2023-12-23 23:34:40'),
(3, 2, 1, 'House Rent', 'Income', 30000.00, 'Demo', '2023-12-23 23:34:41', '2023-12-23 23:34:41'),
(4, 2, 1, 'TAX', 'Deduction', 3000.00, 'Demo', '2023-12-23 23:34:41', '2023-12-23 23:34:41'),
(5, 3, 1, 'House Rent', 'Income', 35000.00, 'Demo', '2023-12-23 23:34:41', '2023-12-23 23:34:41'),
(6, 3, 1, 'TAX', 'Deduction', 3500.00, 'Demo', '2023-12-23 23:34:41', '2023-12-23 23:34:41'),
(7, 4, 1, 'House Rent', 'Income', 20000.00, 'Demo', '2023-12-23 23:35:35', '2023-12-23 23:35:35'),
(8, 4, 1, 'TAX', 'Deduction', 2000.00, 'Demo', '2023-12-23 23:35:35', '2023-12-23 23:35:35'),
(9, 5, 1, 'House Rent', 'Income', 30000.00, 'Demo', '2023-12-23 23:35:35', '2023-12-23 23:35:35'),
(10, 5, 1, 'TAX', 'Deduction', 3000.00, 'Demo', '2023-12-23 23:35:35', '2023-12-23 23:35:35'),
(11, 6, 1, 'House Rent', 'Income', 35000.00, 'Demo', '2023-12-23 23:35:35', '2023-12-23 23:35:35'),
(12, 6, 1, 'TAX', 'Deduction', 3500.00, 'Demo', '2023-12-23 23:35:35', '2023-12-23 23:35:35');

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `id` char(36) NOT NULL,
  `type` varchar(191) NOT NULL,
  `notifiable_type` varchar(191) NOT NULL,
  `notifiable_id` bigint(20) UNSIGNED NOT NULL,
  `data` text NOT NULL,
  `read_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

CREATE TABLE `orders` (
  `id` int(11) NOT NULL,
  `order_no` varchar(255) DEFAULT NULL,
  `customer_id` int(11) DEFAULT NULL,
  `order_date` date DEFAULT NULL,
  `delivery_date` date DEFAULT NULL,
  `done_by` varchar(100) DEFAULT NULL,
  `approveby` varchar(100) DEFAULT NULL,
  `file` varchar(500) DEFAULT NULL,
  `remarks` varchar(255) DEFAULT NULL,
  `status` tinyint(10) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `orders`
--

INSERT INTO `orders` (`id`, `order_no`, `customer_id`, `order_date`, `delivery_date`, `done_by`, `approveby`, `file`, `remarks`, `status`, `created_at`, `updated_at`) VALUES
(1, 'ORD000001', 108, '2024-11-20', '2024-11-22', 'Admin', NULL, NULL, NULL, 0, '2024-11-20 20:19:20', '2024-11-20 20:19:20');

-- --------------------------------------------------------

--
-- Table structure for table `order_details`
--

CREATE TABLE `order_details` (
  `id` int(10) UNSIGNED NOT NULL,
  `order_id` int(11) DEFAULT NULL,
  `stock_type` varchar(255) DEFAULT NULL,
  `stock_date` datetime DEFAULT NULL,
  `order_no` varchar(255) DEFAULT NULL,
  `customer_id` int(10) UNSIGNED DEFAULT NULL,
  `product_id` int(10) UNSIGNED DEFAULT NULL,
  `stock_out_quantity` decimal(18,2) DEFAULT 0.00,
  `stock_out_unit_price` decimal(18,2) DEFAULT 0.00,
  `stock_out_discount` decimal(18,2) DEFAULT 0.00,
  `stock_out_total_amount` decimal(18,2) DEFAULT 0.00,
  `supplier_id` int(10) UNSIGNED DEFAULT NULL,
  `purchase_price` decimal(18,2) DEFAULT 0.00,
  `supplier_invoice_no` varchar(255) DEFAULT NULL,
  `stock_in_quantity` decimal(18,2) DEFAULT 0.00,
  `stock_in_unit_price` decimal(18,2) DEFAULT 0.00,
  `stock_in_discount` decimal(18,2) DEFAULT 0.00,
  `stock_in_total_amount` decimal(18,2) DEFAULT 0.00,
  `done_by` varchar(100) DEFAULT NULL,
  `approveby` int(11) DEFAULT NULL,
  `remarks` varchar(255) DEFAULT NULL,
  `order_date` date DEFAULT NULL,
  `delivery_date` date DEFAULT NULL,
  `status` tinyint(10) DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `order_details`
--

INSERT INTO `order_details` (`id`, `order_id`, `stock_type`, `stock_date`, `order_no`, `customer_id`, `product_id`, `stock_out_quantity`, `stock_out_unit_price`, `stock_out_discount`, `stock_out_total_amount`, `supplier_id`, `purchase_price`, `supplier_invoice_no`, `stock_in_quantity`, `stock_in_unit_price`, `stock_in_discount`, `stock_in_total_amount`, `done_by`, `approveby`, `remarks`, `order_date`, `delivery_date`, `status`, `created_at`, `updated_at`) VALUES
(1, 1, 'Order', '2024-11-20 15:19:20', 'ORD000001', 108, 6, 1.00, 100.00, NULL, 100.00, NULL, 0.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, NULL, '2024-11-20', '2024-11-22', 0, '2024-11-20 20:19:20', '2024-11-20 20:19:20');

-- --------------------------------------------------------

--
-- Table structure for table `other_payments`
--

CREATE TABLE `other_payments` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `employee_id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `amount` double(20,2) NOT NULL DEFAULT 0.00,
  `percentage` decimal(5,2) DEFAULT 0.00,
  `type` tinyint(4) DEFAULT 1,
  `created_by` int(11) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;

-- --------------------------------------------------------

--
-- Table structure for table `overtimes`
--

CREATE TABLE `overtimes` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `employee_id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `number_of_days` int(11) NOT NULL,
  `hours` int(11) NOT NULL,
  `rate` int(11) NOT NULL,
  `created_by` int(11) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;

-- --------------------------------------------------------

--
-- Table structure for table `password_resets`
--

CREATE TABLE `password_resets` (
  `email` varchar(191) NOT NULL,
  `token` varchar(191) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `password_resets`
--

INSERT INTO `password_resets` (`email`, `token`, `created_at`) VALUES
('demo@demo.com', '$2y$10$CuomebRGUjTz4s77BxAkIO9M5la/hLsb1edccHiXfk4SqFcRmhP8O', '2023-11-07 03:01:43'),
('admin@seml.com', '$2y$10$xwSL74bXDWolU0JsTo9nOesNwv9Nc4/.ZTpaUTg19rX.G5yg303pK', '2023-11-07 03:48:36'),
('masumbdonly@gmail.com', '$2y$10$rQbP9HMNPirpjD7y643tI.K7BhSZVLIsE0Qr3SaqxoDAfxgl8S9Ui', '2023-12-24 01:36:17');

-- --------------------------------------------------------

--
-- Table structure for table `payrolls`
--

CREATE TABLE `payrolls` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `employee_id` int(20) NOT NULL,
  `payroll_head_id` int(20) NOT NULL,
  `effective_date` date NOT NULL,
  `remarks` text DEFAULT NULL,
  `created_by` varchar(125) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `payrolls`
--

INSERT INTO `payrolls` (`id`, `employee_id`, `payroll_head_id`, `effective_date`, `remarks`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 38, 3, '2024-04-04', NULL, 'Demo', '2024-04-04 00:33:57', '2024-04-04 00:33:57'),
(2, 38, 4, '2024-04-04', NULL, 'Demo', '2024-04-04 00:33:57', '2024-04-04 00:33:57'),
(3, 38, 5, '2024-04-04', NULL, 'Demo', '2024-04-04 00:33:57', '2024-04-04 00:33:57'),
(7, 39, 3, '2024-04-04', NULL, 'Demo', '2024-04-04 00:33:57', '2024-04-04 00:33:57'),
(8, 39, 4, '2024-04-04', NULL, 'Demo', '2024-04-04 00:33:58', '2024-04-04 00:33:58'),
(9, 39, 5, '2024-04-04', NULL, 'Demo', '2024-04-04 00:33:58', '2024-04-04 00:33:58'),
(13, 40, 3, '2024-04-04', NULL, 'Demo', '2024-04-04 00:33:58', '2024-04-04 00:33:58'),
(14, 40, 4, '2024-04-04', NULL, 'Demo', '2024-04-04 00:33:58', '2024-04-04 00:33:58'),
(15, 40, 5, '2024-04-04', NULL, 'Demo', '2024-04-04 00:33:58', '2024-04-04 00:33:58'),
(16, 40, 6, '2024-04-04', NULL, 'Demo', '2024-04-04 00:33:58', '2024-04-04 00:33:58'),
(17, 40, 7, '2024-04-04', NULL, 'Demo', '2024-04-04 00:33:58', '2024-04-04 00:33:58'),
(19, 44, 3, '2024-03-01', NULL, 'Demo', '2024-04-17 04:45:11', '2024-04-17 04:45:11'),
(20, 44, 4, '2024-03-01', NULL, 'Demo', '2024-04-17 04:45:11', '2024-04-17 04:45:11'),
(21, 44, 5, '2024-03-01', NULL, 'Demo', '2024-04-17 04:45:11', '2024-04-17 04:45:11'),
(22, 44, 6, '2024-03-01', NULL, 'Demo', '2024-04-17 04:45:11', '2024-04-17 04:45:11'),
(23, 44, 7, '2024-03-01', NULL, 'Demo', '2024-04-17 04:45:11', '2024-04-17 04:45:11'),
(24, 44, 8, '2024-03-01', NULL, 'Demo', '2024-04-17 04:45:11', '2024-04-17 04:45:11'),
(25, 43, 3, '2024-03-01', NULL, 'Demo', '2024-04-17 04:46:25', '2024-04-17 04:46:25'),
(26, 43, 4, '2024-03-01', NULL, 'Demo', '2024-04-17 04:46:25', '2024-04-17 04:46:25'),
(27, 43, 5, '2024-03-01', NULL, 'Demo', '2024-04-17 04:46:25', '2024-04-17 04:46:25'),
(28, 43, 6, '2024-03-01', NULL, 'Demo', '2024-04-17 04:46:25', '2024-04-17 04:46:25'),
(29, 43, 7, '2024-03-01', NULL, 'Demo', '2024-04-17 04:46:25', '2024-04-17 04:46:25'),
(30, 43, 8, '2024-03-01', NULL, 'Demo', '2024-04-17 04:46:25', '2024-04-17 04:46:25');

-- --------------------------------------------------------

--
-- Table structure for table `payroll_formulas`
--

CREATE TABLE `payroll_formulas` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `payroll_head` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `formula` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `remarks` text DEFAULT NULL,
  `status` tinyint(4) DEFAULT 1,
  `created_by` varchar(125) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `payroll_formulas`
--

INSERT INTO `payroll_formulas` (`id`, `payroll_head`, `formula`, `remarks`, `status`, `created_by`, `created_at`, `updated_at`) VALUES
(3, '2', '{Basic Salary}/100*10', 'Remarks', 1, 'Demo', '2024-01-02 03:50:05', '2024-01-02 03:55:34'),
(4, '6', '{Basic Salary}/100*10', 'Remarks', 1, 'Demo', '2024-01-02 03:56:11', '2024-04-17 05:53:48'),
(6, '5', '500', 'Paid', 1, 'Demo', '2024-01-02 04:08:04', '2024-01-02 04:08:04'),
(7, '7', '{Basic Salary}/100*30', 'Done', 1, 'Demo', '2024-01-02 04:11:12', '2024-01-02 04:11:12'),
(8, '8', '200', 'Remarks..', 1, 'Demo', '2024-01-02 04:11:59', '2024-01-02 04:11:59'),
(9, '3', '{Basic Salary}/100*35', 'Remarks', 1, 'Demo', '2024-01-02 04:16:36', '2024-01-02 04:18:12'),
(10, '4', '{Basic Salary}', NULL, 1, 'Demo', '2024-04-03 23:35:14', '2024-04-03 23:35:14');

-- --------------------------------------------------------

--
-- Table structure for table `payroll_heads`
--

CREATE TABLE `payroll_heads` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `type` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `status` tinyint(4) DEFAULT 1,
  `created_by` varchar(125) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `payroll_heads`
--

INSERT INTO `payroll_heads` (`id`, `name`, `type`, `status`, `created_by`, `created_at`, `updated_at`) VALUES
(2, 'Attendance Bonus', 'Income', 1, 'Demo', '2024-02-04 03:17:24', '2024-05-30 06:18:22'),
(3, 'Over Time', 'Income', 1, 'Demo', '2024-02-04 03:49:34', '2024-02-04 03:49:34'),
(4, 'Mobile Allow', 'Income', 1, 'Demo', '2024-02-04 03:50:14', '2024-02-04 03:50:14'),
(5, 'Night Allow', 'Income', 1, 'Demo', '2024-02-04 03:50:30', '2024-02-04 03:50:30'),
(6, 'Income tax', 'Deduction', 1, 'Demo', '2024-02-04 03:51:37', '2024-02-04 03:51:37'),
(7, 'Provident Fund', 'Deduction', 1, 'Demo', '2024-02-04 03:51:58', '2024-02-04 03:51:58'),
(8, 'Bus Using', 'Deduction', 1, 'Demo', '2024-02-04 03:52:21', '2024-02-04 03:52:21');

-- --------------------------------------------------------

--
-- Table structure for table `payslip_types`
--

CREATE TABLE `payslip_types` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `status` tinyint(4) DEFAULT 1,
  `created_by` int(11) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;

--
-- Dumping data for table `payslip_types`
--

INSERT INTO `payslip_types` (`id`, `name`, `status`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 'Monthly', 1, 1, '2023-07-13 07:16:54', '2023-07-13 07:18:53'),
(2, 'Hourly', 1, 1, '2023-07-13 07:18:47', '2023-07-16 05:25:57');

-- --------------------------------------------------------

--
-- Table structure for table `pay_slips`
--

CREATE TABLE `pay_slips` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `employee_id` int(11) NOT NULL,
  `net_payble` int(11) NOT NULL,
  `salary_month` varchar(191) NOT NULL,
  `status` int(11) NOT NULL,
  `basic_salary` decimal(11,2) NOT NULL DEFAULT 0.00,
  `allowance` text NOT NULL,
  `commission` text NOT NULL,
  `loan` text NOT NULL,
  `other_payment` text NOT NULL,
  `overtime` text NOT NULL,
  `created_by` int(11) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `pay_slips`
--

INSERT INTO `pay_slips` (`id`, `employee_id`, `net_payble`, `salary_month`, `status`, `basic_salary`, `allowance`, `commission`, `loan`, `other_payment`, `overtime`, `created_by`, `created_at`, `updated_at`) VALUES
(2, 2, 51500, '2023-07', 0, 50000.00, '1500', '0', '0', '0', '0', 1, '2023-12-17 00:04:36', '2023-12-17 00:04:36'),
(3, 3, 50000, '2023-07', 0, 50000.00, '0', '0', '0', '0', '0', 1, '2023-12-17 00:04:36', '2023-12-17 00:04:36'),
(5, 1, 73600, '2023-11', 0, 26000.00, '42600', '8000', '3000', '0', '0', 1, '2023-12-17 00:22:21', '2023-12-17 00:22:21'),
(6, 2, 51500, '2023-11', 0, 50000.00, '1500', '0', '0', '0', '0', 1, '2023-12-17 00:22:21', '2023-12-17 00:22:21'),
(7, 3, 50000, '2023-11', 0, 50000.00, '0', '0', '0', '0', '0', 1, '2023-12-17 00:22:21', '2023-12-17 00:22:21'),
(8, 4, 0, '2023-11', 0, 0.00, '0', '0', '0', '0', '0', 1, '2023-12-17 00:22:21', '2023-12-17 00:22:21'),
(9, 5, 0, '2023-11', 0, 0.00, '0', '0', '0', '0', '0', 1, '2023-12-17 00:22:21', '2023-12-17 00:22:21'),
(10, 6, 0, '2023-11', 0, 0.00, '0', '0', '0', '0', '0', 1, '2023-12-17 00:22:21', '2023-12-17 00:22:21'),
(11, 7, 0, '2023-11', 0, 0.00, '0', '0', '0', '0', '0', 1, '2023-12-17 00:22:21', '2023-12-17 00:22:21'),
(12, 8, 0, '2023-11', 0, 0.00, '0', '0', '0', '0', '0', 1, '2023-12-17 00:22:21', '2023-12-17 00:22:21'),
(13, 10, 0, '2023-11', 0, 0.00, '0', '0', '0', '0', '0', 1, '2023-12-17 00:22:22', '2023-12-17 00:22:22'),
(14, 11, 0, '2023-11', 0, 0.00, '0', '0', '0', '0', '0', 1, '2023-12-17 00:22:22', '2023-12-17 00:22:22'),
(15, 12, 0, '2023-11', 0, 0.00, '0', '0', '0', '0', '0', 1, '2023-12-17 00:22:22', '2023-12-17 00:22:22'),
(16, 13, 0, '2023-11', 0, 0.00, '0', '0', '0', '0', '0', 1, '2023-12-17 00:22:22', '2023-12-17 00:22:22'),
(17, 14, 0, '2023-11', 0, 0.00, '0', '0', '0', '0', '0', 1, '2023-12-17 00:22:22', '2023-12-17 00:22:22');

-- --------------------------------------------------------

--
-- Table structure for table `performance_types`
--

CREATE TABLE `performance_types` (
  `id` int(10) UNSIGNED NOT NULL,
  `performance_name` varchar(255) DEFAULT NULL,
  `status` int(11) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;

--
-- Dumping data for table `performance_types`
--

INSERT INTO `performance_types` (`id`, `performance_name`, `status`, `created_at`, `updated_at`) VALUES
(1, 'Performance 1', 1, '2023-05-22 11:13:44', '2023-05-22 11:26:12'),
(2, 'Performance 2', 1, '2023-05-23 05:06:32', '2023-10-15 23:28:52'),
(3, 'Performance 3', 1, '2023-05-23 10:58:26', '2023-05-23 10:58:26'),
(4, 'Performance 4', 0, '2023-06-05 06:37:17', '2023-10-15 23:28:59');

-- --------------------------------------------------------

--
-- Table structure for table `permissions`
--

CREATE TABLE `permissions` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(191) NOT NULL,
  `guard_name` varchar(191) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `permissions`
--

INSERT INTO `permissions` (`id`, `name`, `guard_name`, `created_at`, `updated_at`) VALUES
(1, 'read user management', 'web', '2023-07-25 04:29:51', '2023-07-25 04:29:51'),
(2, 'write user management', 'web', '2023-07-25 04:29:51', '2023-07-25 04:29:51'),
(3, 'create user management', 'web', '2023-07-25 04:29:51', '2023-07-25 04:29:51'),
(4, 'read content management', 'web', '2023-07-25 04:29:51', '2023-07-25 04:29:51'),
(5, 'write content management', 'web', '2023-07-25 04:29:51', '2023-07-25 04:29:51'),
(6, 'create content management', 'web', '2023-07-25 04:29:51', '2023-07-25 04:29:51'),
(7, 'read financial management', 'web', '2023-07-25 04:29:51', '2023-07-25 04:29:51'),
(8, 'write financial management', 'web', '2023-07-25 04:29:51', '2023-07-25 04:29:51'),
(9, 'create financial management', 'web', '2023-07-25 04:29:52', '2023-07-25 04:29:52'),
(10, 'read reporting', 'web', '2023-07-25 04:29:52', '2023-07-25 04:29:52'),
(11, 'write reporting', 'web', '2023-07-25 04:29:52', '2023-07-25 04:29:52'),
(12, 'create reporting', 'web', '2023-07-25 04:29:52', '2023-07-25 04:29:52'),
(13, 'read payroll', 'web', '2023-07-25 04:29:52', '2023-07-25 04:29:52'),
(14, 'write payroll', 'web', '2023-07-25 04:29:52', '2023-07-25 04:29:52'),
(15, 'create payroll', 'web', '2023-07-25 04:29:52', '2023-07-25 04:29:52'),
(16, 'read disputes management', 'web', '2023-07-25 04:29:52', '2023-07-25 04:29:52'),
(17, 'write disputes management', 'web', '2023-07-25 04:29:52', '2023-07-25 04:29:52'),
(18, 'create disputes management', 'web', '2023-07-25 04:29:52', '2023-07-25 04:29:52'),
(19, 'read api controls', 'web', '2023-07-25 04:29:52', '2023-07-25 04:29:52'),
(20, 'write api controls', 'web', '2023-07-25 04:29:52', '2023-07-25 04:29:52'),
(21, 'create api controls', 'web', '2023-07-25 04:29:52', '2023-07-25 04:29:52'),
(22, 'read database management', 'web', '2023-07-25 04:29:52', '2023-07-25 04:29:52'),
(23, 'write database management', 'web', '2023-07-25 04:29:52', '2023-07-25 04:29:52'),
(24, 'create database management', 'web', '2023-07-25 04:29:52', '2023-07-25 04:29:52'),
(25, 'read repository management', 'web', '2023-07-25 04:29:52', '2023-07-25 04:29:52'),
(26, 'write repository management', 'web', '2023-07-25 04:29:52', '2023-07-25 04:29:52'),
(27, 'create repository management', 'web', '2023-07-25 04:29:52', '2023-07-25 04:29:52'),
(40, 'read employee branch', 'web', '2023-07-26 23:25:05', '2023-07-26 23:25:05'),
(41, 'write employee branch', 'web', '2023-07-26 23:44:52', '2023-07-26 23:44:52'),
(42, 'create employee branch', 'web', '2023-07-26 23:45:04', '2023-07-26 23:45:04'),
(49, 'read employee department', 'web', '2023-07-27 00:22:23', '2023-07-27 00:22:23'),
(50, 'write employee department', 'web', '2023-07-27 00:22:32', '2023-07-27 00:22:32'),
(51, 'create employee department', 'web', '2023-07-27 00:22:41', '2023-07-27 00:22:41'),
(52, 'read employee designation', 'web', '2023-07-27 00:29:15', '2023-07-27 00:29:15'),
(53, 'write employee designation', 'web', '2023-07-27 00:29:28', '2023-07-27 00:29:28'),
(54, 'create employee designation', 'web', '2023-07-27 00:29:38', '2023-07-27 00:29:38'),
(55, 'read employee', 'web', '2023-07-27 00:56:55', '2023-07-27 00:56:55'),
(56, 'write employee', 'web', '2023-07-27 00:57:03', '2023-07-27 00:57:03'),
(57, 'create employee', 'web', '2023-07-27 00:57:30', '2023-07-27 00:57:30'),
(73, 'read employee ledger', 'web', '2023-07-29 23:23:46', '2023-07-29 23:23:46'),
(74, 'create employee ledger', 'web', '2023-07-29 23:24:15', '2023-07-29 23:24:15'),
(80, 'read leave setting', 'web', '2023-07-30 00:25:29', '2023-07-30 00:25:29'),
(81, 'create leave setting', 'web', '2023-07-30 00:25:38', '2023-07-30 00:25:38'),
(82, 'read leave entry', 'web', '2023-07-30 00:44:06', '2023-07-30 00:44:06'),
(83, 'create leave entry', 'web', '2023-07-30 00:44:17', '2023-07-30 00:44:17'),
(86, 'read leave approved department', 'web', '2023-07-30 01:11:47', '2023-07-30 01:11:47'),
(87, 'create leave approved department', 'web', '2023-07-30 01:11:57', '2023-07-30 01:11:57'),
(90, 'read leave approved hr', 'web', '2023-07-30 01:17:04', '2023-07-30 01:17:04'),
(91, 'create leave approved hr', 'web', '2023-07-30 01:17:21', '2023-07-30 01:17:21'),
(93, 'read leave approved management', 'web', '2023-07-30 02:22:41', '2023-07-30 02:22:41'),
(94, 'create leave approved management', 'web', '2023-07-30 02:22:50', '2023-07-30 02:22:50'),
(95, 'read delayin earlyout', 'web', '2023-07-30 03:13:33', '2023-07-30 03:13:33'),
(96, 'write delayin earlyout', 'web', '2023-07-30 03:13:46', '2023-07-30 03:13:46'),
(97, 'create delayin earlyout', 'web', '2023-07-30 03:14:03', '2023-07-30 03:14:03'),
(99, 'read performance type', 'web', '2023-07-30 04:28:35', '2023-07-30 04:28:35'),
(100, 'write performance type', 'web', '2023-07-30 04:28:43', '2023-07-30 04:28:43'),
(101, 'create performance type', 'web', '2023-07-30 04:28:53', '2023-07-30 04:28:53'),
(102, 'read employee performance', 'web', '2023-07-30 04:48:46', '2023-07-30 04:48:46'),
(103, 'write employee performance', 'web', '2023-07-30 04:48:54', '2023-07-30 04:48:54'),
(104, 'create employee performance', 'web', '2023-07-30 04:49:02', '2023-07-30 04:49:02'),
(109, 'read payslip type', 'web', '2023-07-31 01:26:05', '2023-07-31 01:26:05'),
(110, 'write payslip type', 'web', '2023-07-31 01:26:19', '2023-07-31 01:26:19'),
(111, 'create payslip type', 'web', '2023-07-31 01:26:28', '2023-07-31 01:26:28'),
(112, 'read allowance option', 'web', '2023-07-31 01:34:39', '2023-07-31 01:34:39'),
(113, 'write allowance option', 'web', '2023-07-31 01:34:48', '2023-07-31 01:34:48'),
(114, 'create allowance option', 'web', '2023-07-31 01:34:55', '2023-07-31 01:34:55'),
(115, 'read loan option', 'web', '2023-07-31 01:50:51', '2023-07-31 01:50:51'),
(116, 'write loan option', 'web', '2023-07-31 01:51:00', '2023-07-31 01:51:00'),
(117, 'create loan option', 'web', '2023-07-31 01:51:08', '2023-07-31 01:51:08'),
(118, 'read promotion', 'web', '2023-07-31 03:02:51', '2023-07-31 03:02:51'),
(119, 'write promotion', 'web', '2023-07-31 03:03:10', '2023-07-31 03:03:10'),
(120, 'create promotion', 'web', '2023-07-31 03:03:34', '2023-07-31 03:03:34'),
(121, 'read set salaries', 'web', '2023-07-31 03:08:28', '2023-07-31 03:08:28'),
(122, 'write set salaries', 'web', '2023-07-31 03:08:37', '2023-07-31 03:08:37'),
(123, 'create set salaries', 'web', '2023-07-31 03:08:45', '2023-07-31 03:08:45'),
(124, 'read payslips', 'web', '2023-07-31 03:11:20', '2023-07-31 03:11:20'),
(125, 'write payslips', 'web', '2023-07-31 03:11:28', '2023-07-31 03:11:28'),
(126, 'create payslips', 'web', '2023-07-31 03:11:39', '2023-07-31 03:11:39'),
(127, 'read resignation', 'web', '2023-07-31 04:39:44', '2023-07-31 04:39:44'),
(128, 'write resignation', 'web', '2023-07-31 04:40:03', '2023-07-31 04:40:03'),
(129, 'create resignation', 'web', '2023-07-31 04:40:12', '2023-07-31 04:40:12'),
(131, 'read termination', 'web', '2023-07-31 04:54:50', '2023-07-31 04:54:50'),
(132, 'write termination', 'web', '2023-07-31 04:55:04', '2023-07-31 04:55:04'),
(133, 'create termination', 'web', '2023-07-31 04:55:22', '2023-07-31 04:55:22'),
(134, 'read announcement', 'web', '2023-07-31 05:27:17', '2023-07-31 05:27:17'),
(135, 'write announcement', 'web', '2023-07-31 05:27:37', '2023-07-31 05:27:37'),
(136, 'create announcement', 'web', '2023-07-31 05:27:54', '2023-07-31 05:27:54'),
(137, 'read holiday', 'web', '2023-07-31 05:44:45', '2023-07-31 05:44:45'),
(138, 'write holiday', 'web', '2023-07-31 05:45:10', '2023-07-31 05:45:10'),
(139, 'create holiday', 'web', '2023-07-31 05:45:27', '2023-07-31 05:45:27'),
(140, 'read meeting', 'web', '2023-07-31 05:58:53', '2023-07-31 05:58:53'),
(141, 'write meeting', 'web', '2023-07-31 05:59:12', '2023-07-31 05:59:12'),
(142, 'create meeting', 'web', '2023-07-31 05:59:25', '2023-07-31 05:59:25'),
(143, 'read dbbackup', 'web', '2023-07-31 23:43:15', '2023-07-31 23:43:15'),
(144, 'write dbbackup', 'web', '2023-07-31 23:43:33', '2023-07-31 23:43:33'),
(145, 'create dbbackup', 'web', '2023-07-31 23:43:50', '2023-07-31 23:43:50'),
(153, 'read attendance', 'web', '2023-08-02 04:41:21', '2023-08-02 04:41:21'),
(154, 'write attendance', 'web', '2023-08-02 04:41:36', '2023-08-02 04:41:36'),
(155, 'create attendance', 'web', '2023-08-02 04:41:51', '2023-08-02 04:41:51'),
(156, 'read income head', 'web', '2023-12-17 01:59:34', '2023-12-17 01:59:34'),
(157, 'write income head', 'web', '2023-12-17 01:59:43', '2023-12-17 01:59:43'),
(158, 'create income head', 'web', '2023-12-17 01:59:52', '2023-12-17 01:59:52'),
(159, 'read deduction head', 'web', '2023-12-17 03:27:23', '2023-12-17 03:27:23'),
(160, 'write deduction head', 'web', '2023-12-17 03:27:45', '2023-12-17 03:27:45'),
(161, 'create deduction head', 'web', '2023-12-17 03:27:55', '2023-12-17 03:27:55'),
(162, 'read monthly salary', 'web', '2023-12-21 04:11:13', '2023-12-21 04:11:13'),
(163, 'write monthly salary', 'web', '2023-12-21 04:11:27', '2023-12-21 04:11:27'),
(164, 'create monthly salary', 'web', '2023-12-21 04:11:34', '2023-12-21 04:11:34'),
(165, 'read timetable', 'web', '2024-01-15 04:30:48', '2024-01-15 04:30:48'),
(166, 'write timetable', 'web', '2024-01-15 04:30:58', '2024-01-15 04:30:58'),
(167, 'create timetable', 'web', '2024-01-15 04:31:06', '2024-01-15 04:31:06'),
(168, 'write supplier', 'web', '2024-01-21 04:00:36', '2024-01-21 04:00:36'),
(169, 'read supplier', 'web', '2024-01-21 04:01:10', '2024-01-21 04:01:10'),
(170, 'create supplier', 'web', '2024-01-21 04:01:17', '2024-01-21 04:01:17'),
(171, 'read supplier ledger', 'web', '2024-01-21 04:12:19', '2024-01-21 04:12:19'),
(172, 'write supplier ledger', 'web', '2024-01-21 04:12:36', '2024-01-21 04:12:36'),
(173, 'create supplier ledger', 'web', '2024-01-21 04:12:42', '2024-01-21 04:12:42'),
(174, 'read customer', 'web', '2024-01-21 04:15:31', '2024-01-21 04:15:31'),
(175, 'write customer', 'web', '2024-01-21 04:15:41', '2024-01-21 04:15:41'),
(176, 'create customer', 'web', '2024-01-21 04:15:46', '2024-01-21 04:15:46'),
(177, 'read customer ledger', 'web', '2024-01-21 04:15:57', '2024-01-21 04:15:57'),
(178, 'write customer ledger', 'web', '2024-01-21 04:16:03', '2024-01-21 04:16:03'),
(179, 'create customer ledger', 'web', '2024-01-21 04:16:13', '2024-01-21 04:16:13'),
(180, 'read category', 'web', '2024-01-21 04:21:25', '2024-01-21 04:21:25'),
(181, 'write category', 'web', '2024-01-21 04:21:33', '2024-01-21 04:21:33'),
(182, 'create category', 'web', '2024-01-21 04:21:39', '2024-01-21 04:21:39'),
(183, 'read sub category', 'web', '2024-01-21 04:21:54', '2024-01-21 04:21:54'),
(184, 'write sub category', 'web', '2024-01-21 04:22:00', '2024-01-21 04:22:00'),
(185, 'create sub category', 'web', '2024-01-21 04:22:05', '2024-01-21 04:22:05'),
(186, 'read brand', 'web', '2024-01-21 04:22:19', '2024-01-21 04:22:19'),
(187, 'write brand', 'web', '2024-01-21 04:22:24', '2024-01-21 04:22:24'),
(188, 'create brand', 'web', '2024-01-21 04:22:28', '2024-01-21 04:22:28'),
(189, 'read color', 'web', '2024-01-21 04:22:50', '2024-01-21 04:22:50'),
(190, 'write color', 'web', '2024-01-21 04:22:57', '2024-01-21 04:22:57'),
(191, 'create color', 'web', '2024-01-21 04:23:02', '2024-01-21 04:23:02'),
(192, 'read size', 'web', '2024-01-21 04:23:14', '2024-01-21 04:23:14'),
(193, 'write size', 'web', '2024-01-21 04:23:18', '2024-01-21 04:23:18'),
(194, 'create size', 'web', '2024-01-21 04:23:23', '2024-01-21 04:23:23'),
(195, 'read product', 'web', '2024-01-21 04:39:35', '2024-01-21 04:39:35'),
(196, 'write product', 'web', '2024-01-21 04:40:12', '2024-01-21 04:40:12'),
(197, 'create product', 'web', '2024-01-21 04:40:22', '2024-01-21 04:40:22'),
(198, 'read purchase', 'web', '2024-01-21 04:43:58', '2024-01-21 04:43:58'),
(199, 'write purchase', 'web', '2024-01-21 04:44:04', '2024-01-21 04:44:04'),
(200, 'create purchase', 'web', '2024-01-21 04:44:09', '2024-01-21 04:44:09'),
(201, 'read sales', 'web', '2024-01-21 04:44:23', '2024-01-21 04:44:23'),
(202, 'write sales', 'web', '2024-01-21 04:44:53', '2024-01-21 04:44:53'),
(203, 'create sales', 'web', '2024-01-21 04:44:58', '2024-01-21 04:44:58'),
(204, 'read purchase report', 'web', '2024-01-21 04:45:17', '2024-01-21 04:45:17'),
(205, 'write purchase report', 'web', '2024-01-21 04:45:24', '2024-01-21 04:45:24'),
(206, 'create purchase report', 'web', '2024-01-21 04:45:29', '2024-01-21 04:45:29'),
(207, 'read sales report', 'web', '2024-01-21 04:45:45', '2024-01-21 04:45:45'),
(208, 'write sales report', 'web', '2024-01-21 04:45:53', '2024-01-21 04:45:53'),
(209, 'create sales report', 'web', '2024-01-21 04:46:02', '2024-01-21 04:46:02'),
(210, 'read stock report', 'web', '2024-01-21 04:46:21', '2024-01-21 04:46:21'),
(211, 'read cost sheet', 'web', '2024-01-21 04:49:09', '2024-01-21 04:49:09'),
(212, 'write cost sheet', 'web', '2024-01-21 04:49:17', '2024-01-21 04:49:17'),
(213, 'create cost sheet', 'web', '2024-01-21 04:49:22', '2024-01-21 04:49:22'),
(214, 'read product order', 'web', '2024-01-21 05:06:02', '2024-01-21 05:06:02'),
(215, 'write product order', 'web', '2024-01-21 05:06:13', '2024-01-21 05:06:13'),
(216, 'create product order', 'web', '2024-01-21 05:06:22', '2024-01-21 05:06:22'),
(220, 'read payroll head', 'web', '2024-04-08 03:47:41', '2024-04-08 03:47:41'),
(221, 'write payroll head', 'web', '2024-04-08 03:48:13', '2024-04-08 03:48:13'),
(222, 'create payroll head', 'web', '2024-04-08 03:48:22', '2024-04-08 03:48:22'),
(223, 'read payroll formula', 'web', '2024-04-08 03:54:19', '2024-04-08 03:54:19'),
(224, 'write payroll formula', 'web', '2024-04-08 03:54:31', '2024-04-08 03:54:31'),
(225, 'create payroll formula', 'web', '2024-04-08 03:54:41', '2024-04-08 03:54:41'),
(226, 'read payroll add', 'web', '2024-04-08 22:58:11', '2024-04-08 22:58:11'),
(227, 'write payroll add', 'web', '2024-04-08 22:58:28', '2024-04-08 22:58:28'),
(228, 'create payroll add', 'web', '2024-04-08 22:58:36', '2024-04-08 22:58:36'),
(229, 'read company setting', 'web', '2024-04-08 23:19:43', '2024-04-08 23:19:43'),
(230, 'write company setting', 'web', '2024-04-08 23:19:55', '2024-04-08 23:19:55'),
(231, 'create company setting', 'web', '2024-04-08 23:20:04', '2024-04-08 23:20:04'),
(232, 'read billofmaterials', 'web', '2024-04-22 23:51:10', '2024-04-22 23:51:10'),
(233, 'write billofmaterials', 'web', '2024-04-22 23:51:18', '2024-04-22 23:51:18'),
(234, 'create billofmaterials', 'web', '2024-04-22 23:51:30', '2024-04-22 23:51:30'),
(235, 'read finalproductions', 'web', '2024-04-22 23:54:32', '2024-04-22 23:54:32'),
(236, 'write finalproductions', 'web', '2024-04-22 23:54:41', '2024-04-22 23:54:41'),
(237, 'create finalproductions', 'web', '2024-04-22 23:54:49', '2024-04-22 23:54:49'),
(238, 'read finalproduction report', 'web', '2024-04-23 00:00:49', '2024-04-23 00:00:49'),
(239, 'write finalproduction report', 'web', '2024-04-23 00:00:58', '2024-04-23 00:00:58'),
(240, 'create finalproduction report', 'web', '2024-04-23 00:01:04', '2024-04-23 00:01:04'),
(241, 'read product type', 'web', '2024-05-08 07:55:53', '2024-05-08 07:55:53'),
(242, 'write product type', 'web', '2024-05-08 07:56:01', '2024-05-08 07:56:01'),
(243, 'create product type', 'web', '2024-05-08 07:56:09', '2024-05-08 07:56:09'),
(244, 'read unit', 'web', '2024-05-08 08:03:25', '2024-05-08 08:03:25'),
(245, 'write unit', 'web', '2024-05-08 08:03:36', '2024-05-08 08:03:36'),
(246, 'create unit', 'web', '2024-05-08 08:03:43', '2024-05-08 08:03:43'),
(247, 'read product fragrance', 'web', '2024-05-08 10:08:30', '2024-05-08 10:08:30'),
(248, 'write product fragrance', 'web', '2024-05-08 10:08:38', '2024-05-08 10:08:38'),
(249, 'create product fragrance', 'web', '2024-05-08 10:08:47', '2024-05-08 10:08:47'),
(250, 'read customer type', 'web', '2024-05-14 11:38:53', '2024-05-14 11:38:53'),
(251, 'write customer type', 'web', '2024-05-14 11:39:02', '2024-05-14 11:39:02'),
(252, 'create customer type', 'web', '2024-05-14 11:39:10', '2024-05-14 11:39:10'),
(253, 'delete customer type', 'web', '2024-05-16 08:54:45', '2024-05-16 08:54:45'),
(254, 'read requisition', 'web', '2024-05-16 11:05:31', '2024-05-16 11:05:31'),
(255, 'write requisition', 'web', '2024-05-16 11:05:49', '2024-05-16 11:05:49'),
(256, 'create requisition', 'web', '2024-05-16 11:06:04', '2024-05-16 11:06:04'),
(257, 'read requisition list', 'web', '2024-05-16 11:06:37', '2024-05-16 11:06:37'),
(258, 'read requisition approved list', 'web', '2024-05-20 07:04:49', '2024-05-20 07:04:49'),
(259, 'read billofmaterials list', 'web', '2024-05-23 08:43:01', '2024-05-23 08:43:01'),
(260, 'write billofmaterials list', 'web', '2024-05-23 08:43:39', '2024-05-23 08:43:39'),
(261, 'create billofmaterials list', 'web', '2024-05-23 08:43:50', '2024-05-23 08:43:50'),
(262, 'create sales report datewise', 'web', '2024-06-12 09:57:21', '2024-06-12 09:57:21'),
(263, 'write sales report datewise', 'web', '2024-06-12 09:58:17', '2024-06-12 09:58:17'),
(264, 'read sales report datewise', 'web', '2024-06-12 09:58:41', '2024-06-12 09:58:41'),
(265, 'read finance transaction', 'web', '2024-07-04 11:07:52', '2024-07-04 11:07:52'),
(266, 'write finance transaction', 'web', '2024-07-04 11:08:31', '2024-07-04 11:08:31'),
(267, 'create finance transaction', 'web', '2024-07-04 11:15:38', '2024-07-04 11:15:38'),
(268, 'read finance account', 'web', '2024-07-04 11:24:46', '2024-07-04 11:24:46'),
(269, 'write finance account', 'web', '2024-07-04 11:25:45', '2024-07-04 11:25:45'),
(270, 'create finance account', 'web', '2024-07-04 11:25:57', '2024-07-04 11:25:57'),
(271, 'read finance group', 'web', '2024-07-04 11:27:08', '2024-07-04 11:27:08'),
(272, 'write finance group', 'web', '2024-07-04 11:27:43', '2024-07-04 11:27:43'),
(273, 'create finance group', 'web', '2024-07-04 11:27:58', '2024-07-04 11:27:58'),
(274, 'read received voucher', 'web', '2024-07-04 11:40:25', '2024-07-04 11:40:25'),
(275, 'write received voucher', 'web', '2024-07-04 11:40:43', '2024-07-04 11:40:43'),
(276, 'create received voucher', 'web', '2024-07-04 11:41:08', '2024-07-04 11:41:08'),
(277, 'read payment voucher', 'web', '2024-07-04 12:26:29', '2024-07-04 12:26:29'),
(278, 'write payment voucher', 'web', '2024-07-04 12:26:50', '2024-07-04 12:26:50'),
(279, 'create payment voucher', 'web', '2024-07-04 12:27:00', '2024-07-04 12:27:00'),
(280, 'read general ledger', 'web', '2024-07-04 12:51:27', '2024-07-04 12:51:27'),
(284, 'read order', 'web', '2024-09-02 07:11:11', '2024-09-02 07:11:11'),
(285, 'write order', 'web', '2024-09-02 07:12:48', '2024-09-02 07:12:48'),
(286, 'create order', 'web', '2024-09-02 07:12:58', '2024-09-02 07:12:58'),
(288, 'read warehouse', 'web', '2024-09-11 08:23:31', '2024-09-11 08:23:31'),
(289, 'write warehouse', 'web', '2024-09-11 08:24:00', '2024-09-11 08:24:00'),
(290, 'create warehouse', 'web', '2024-09-11 08:24:05', '2024-09-11 08:24:05'),
(291, 'read product service', 'web', '2024-11-04 11:52:55', '2024-11-04 11:52:55'),
(292, 'write product service', 'web', '2024-11-04 11:53:01', '2024-11-04 11:53:01'),
(293, 'create product service', 'web', '2024-11-04 11:53:07', '2024-11-04 11:53:07'),
(294, 'read pending product service', 'web', '2024-11-04 11:53:28', '2024-11-04 11:53:28'),
(295, 'read complete product service', 'web', '2024-11-04 11:53:41', '2024-11-04 11:53:41'),
(296, 'read item wise profit', 'web', '2024-11-04 11:59:45', '2024-11-04 11:59:45'),
(297, 'read invoice wise profit', 'web', '2024-11-04 11:59:55', '2024-11-04 11:59:55');

-- --------------------------------------------------------

--
-- Table structure for table `personal_access_tokens`
--

CREATE TABLE `personal_access_tokens` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `tokenable_type` varchar(191) NOT NULL,
  `tokenable_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(191) NOT NULL,
  `token` varchar(64) NOT NULL,
  `abilities` text DEFAULT NULL,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `productions`
--

CREATE TABLE `productions` (
  `id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `quantity` decimal(18,2) NOT NULL DEFAULT 0.00,
  `unit_id` int(50) DEFAULT NULL,
  `done_by` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `production_bill_of_matrials`
--

CREATE TABLE `production_bill_of_matrials` (
  `id` int(11) NOT NULL,
  `production_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `quantity` decimal(18,2) NOT NULL DEFAULT 0.00,
  `product_unit` int(50) DEFAULT NULL,
  `type` int(11) NOT NULL,
  `done_by` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `products`
--

CREATE TABLE `products` (
  `id` int(10) UNSIGNED NOT NULL,
  `supplier_id` int(10) UNSIGNED DEFAULT NULL,
  `type_id` int(20) UNSIGNED DEFAULT NULL,
  `category_id` int(10) UNSIGNED DEFAULT NULL,
  `sub_category_id` int(10) UNSIGNED DEFAULT NULL,
  `brand_id` int(10) UNSIGNED DEFAULT NULL,
  `color_id` int(10) UNSIGNED DEFAULT NULL,
  `size_id` int(10) UNSIGNED DEFAULT NULL,
  `unit_id` int(10) UNSIGNED DEFAULT NULL,
  `fragrance_id` int(11) DEFAULT NULL,
  `product_code` varchar(255) DEFAULT NULL,
  `hs_code` varchar(255) DEFAULT NULL,
  `article_no` varchar(255) DEFAULT NULL,
  `product_name` varchar(255) NOT NULL,
  `product_slug` varchar(255) DEFAULT NULL,
  `country_Of_origin` varchar(255) DEFAULT NULL,
  `product_thickness` varchar(255) DEFAULT NULL,
  `pack_size` decimal(18,2) NOT NULL DEFAULT 0.00,
  `purchase_price` decimal(30,3) DEFAULT NULL,
  `profit_percent` decimal(18,2) DEFAULT NULL,
  `wholesale_price` decimal(30,3) DEFAULT NULL,
  `sales_price` decimal(30,3) DEFAULT NULL,
  `credit_sales_price` decimal(30,3) DEFAULT NULL,
  `minimum_alert_quantity` decimal(18,2) DEFAULT NULL,
  `is_taxable` int(11) DEFAULT NULL,
  `tax_rate` decimal(18,2) DEFAULT NULL,
  `product_image1` varchar(255) DEFAULT NULL,
  `product_image2` varchar(255) DEFAULT NULL,
  `product_description` longtext DEFAULT NULL,
  `product_remarks` longtext DEFAULT NULL,
  `order` varchar(255) DEFAULT '0',
  `is_purchaseable` int(11) NOT NULL,
  `is_saleable` int(11) NOT NULL,
  `is_produceable` int(11) NOT NULL,
  `is_consumable` int(11) NOT NULL,
  `is_serviceable` int(11) DEFAULT 0,
  `status` int(11) DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `products`
--

INSERT INTO `products` (`id`, `supplier_id`, `type_id`, `category_id`, `sub_category_id`, `brand_id`, `color_id`, `size_id`, `unit_id`, `fragrance_id`, `product_code`, `hs_code`, `article_no`, `product_name`, `product_slug`, `country_Of_origin`, `product_thickness`, `pack_size`, `purchase_price`, `profit_percent`, `wholesale_price`, `sales_price`, `credit_sales_price`, `minimum_alert_quantity`, `is_taxable`, `tax_rate`, `product_image1`, `product_image2`, `product_description`, `product_remarks`, `order`, `is_purchaseable`, `is_saleable`, `is_produceable`, `is_consumable`, `is_serviceable`, `status`, `created_at`, `updated_at`) VALUES
(1, NULL, 1, 1, NULL, NULL, NULL, NULL, 1, NULL, 'PC01', NULL, NULL, 'Mineral water 25ml', NULL, NULL, NULL, 0.00, 20.000, NULL, NULL, 25.000, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 0, 1, 0, '2024-09-11 12:50:46', '2024-09-24 16:04:56'),
(2, NULL, 1, 2, NULL, NULL, NULL, NULL, 2, NULL, 'PC02', NULL, NULL, 'Mineral Water 500ml', NULL, NULL, NULL, 0.00, 20.000, NULL, NULL, 30.000, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 0, 1, 0, '2024-09-12 05:30:53', '2024-09-24 16:05:07'),
(3, NULL, 1, 2, NULL, 2, NULL, NULL, 5, NULL, NULL, NULL, NULL, 'RO-105', NULL, NULL, NULL, 0.00, 7100.000, NULL, NULL, 10000.000, NULL, NULL, 1, 15.00, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 0, 1, 1, '2024-09-17 21:59:37', '2024-09-24 16:31:00'),
(4, NULL, 1, 1, NULL, 1, NULL, NULL, 5, NULL, 'jcp-DF-105000001', NULL, NULL, 'DF-105', NULL, NULL, NULL, 0.00, 2347.000, NULL, NULL, 4000.000, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 0, 1, 1, '2024-09-17 22:10:38', '2024-09-25 19:25:01'),
(5, NULL, 2, 4, NULL, 3, NULL, NULL, 5, NULL, NULL, NULL, NULL, 'Inline BIg Sediment Filter', NULL, NULL, NULL, 0.00, 150.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-24 16:39:24', '2024-09-24 16:40:42'),
(6, NULL, 2, 4, NULL, 3, 1, 1, 5, NULL, NULL, NULL, NULL, '10 inch pp filter', NULL, NULL, NULL, 0.00, 33.000, NULL, NULL, 100.000, NULL, NULL, 1, NULL, NULL, NULL, 'Dot type', NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-24 16:53:28', '2024-09-24 16:53:28'),
(7, NULL, 2, 4, NULL, 3, NULL, 2, 5, NULL, NULL, NULL, NULL, '10 Inch CTO Filter', NULL, NULL, NULL, 0.00, 90.000, NULL, NULL, 250.000, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-24 18:10:55', '2024-09-24 18:10:55'),
(8, NULL, 2, 4, NULL, 3, NULL, 2, 5, NULL, NULL, NULL, NULL, '10 Inch GAC Filter', NULL, NULL, NULL, 0.00, 90.000, NULL, NULL, 250.000, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-24 18:13:01', '2024-09-24 18:13:01'),
(9, NULL, 2, 4, NULL, NULL, NULL, 3, 5, NULL, NULL, NULL, NULL, 'Single Clamp Big', NULL, NULL, NULL, 0.00, 8.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-24 18:21:15', '2024-09-26 21:50:30'),
(10, NULL, 2, 4, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, 'Double Clamp Big Small', NULL, NULL, NULL, 0.00, 8.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-24 18:24:19', '2024-09-26 21:50:04'),
(11, NULL, 2, 4, NULL, NULL, NULL, 7, 5, NULL, NULL, NULL, NULL, 'RO- Male Elbow', NULL, NULL, NULL, 0.00, 8.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-24 18:27:53', '2024-09-26 21:49:37'),
(12, NULL, 2, 4, NULL, 3, NULL, NULL, 5, NULL, NULL, NULL, NULL, 'RO Purifier Faucet SS', NULL, NULL, NULL, 0.00, 230.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-24 18:31:35', '2024-09-26 21:49:15'),
(13, NULL, 2, 4, NULL, NULL, NULL, 2, 5, NULL, NULL, NULL, NULL, '10 Inch Housing Wrench White', NULL, NULL, NULL, 0.00, 15.000, NULL, NULL, 100.000, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-24 18:33:24', '2024-09-26 21:48:55'),
(14, NULL, 2, 4, NULL, NULL, NULL, 9, 5, NULL, NULL, NULL, NULL, '6mm Water Connector Ball Valve', NULL, NULL, NULL, 0.00, 80.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-24 18:35:38', '2024-09-26 21:48:27'),
(15, NULL, 2, 4, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, 'Adapter (Input 100-220V, AC-0.6Amp, Output-24V DC-1.5Amp.)', NULL, NULL, NULL, 0.00, 350.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, 'Input 100-220V, AC-0.6Amp, Output-24V DC-1.5Amp.', NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-24 18:37:13', '2024-09-26 21:47:53'),
(16, NULL, 2, 4, NULL, NULL, NULL, 7, 5, NULL, NULL, NULL, NULL, 'High Pressure Switch', NULL, NULL, NULL, 0.00, 75.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-24 18:40:34', '2024-09-26 21:46:52'),
(17, NULL, 2, 4, NULL, NULL, 1, NULL, 5, NULL, NULL, NULL, NULL, 'Low Pressure Switch', NULL, NULL, NULL, 0.00, 75.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-24 18:44:08', '2024-09-26 21:46:31'),
(18, NULL, 2, 4, NULL, NULL, 8, NULL, 5, NULL, NULL, NULL, NULL, 'Solenoid Valve', NULL, NULL, NULL, 0.00, 170.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-24 18:47:25', '2024-09-26 21:46:12'),
(19, NULL, 2, 4, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, 'Flow Restrictor', NULL, NULL, NULL, 0.00, 35.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-24 18:49:03', '2024-09-26 21:45:53'),
(20, NULL, 2, 2, NULL, NULL, 1, 10, 5, NULL, NULL, NULL, NULL, 'Water Storage Tank', NULL, NULL, NULL, 0.00, 2500.000, NULL, NULL, 3700.000, NULL, NULL, 1, NULL, NULL, NULL, 'Cap-3.2G , Max Pressure - 100 PSI.', NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-24 18:54:10', '2024-09-26 21:44:35'),
(21, NULL, 2, 4, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, 'Tank Valve', NULL, NULL, NULL, 0.00, 35.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-24 18:55:21', '2024-09-26 21:43:25'),
(22, NULL, 2, 4, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, 'Manual Flash valve', NULL, NULL, NULL, 0.00, 50.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-24 18:56:10', '2024-09-26 21:43:03'),
(23, NULL, 2, 4, NULL, NULL, NULL, 9, 5, NULL, NULL, NULL, NULL, 'Tee Connector', NULL, NULL, NULL, 0.00, 15.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-24 18:57:22', '2024-09-26 21:42:32'),
(24, NULL, 2, 4, NULL, NULL, NULL, 12, 5, NULL, NULL, NULL, NULL, 'Adapter 100 GPD', NULL, NULL, NULL, 0.00, 600.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, 'Output-24V DC-3 Amp.', NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-24 19:03:11', '2024-09-26 21:42:11'),
(25, NULL, 2, 4, NULL, NULL, NULL, 13, 5, NULL, NULL, NULL, NULL, 'Adapter 200 GPD', NULL, NULL, NULL, 0.00, 750.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, 'Output-24V DC-3 Amp.', NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-24 19:10:27', '2024-09-26 21:41:20'),
(26, NULL, 2, 4, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, 'Water Connector SS Nipple', NULL, NULL, NULL, 0.00, 90.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-24 19:12:03', '2024-09-26 21:40:44'),
(27, NULL, 2, 4, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, 'Inline Slim Mineral Filter Heron', NULL, NULL, NULL, 0.00, 150.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-24 19:14:38', '2024-09-26 21:40:20'),
(28, NULL, 2, 4, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, 'Inline Slim Alkaline Filter Heron', NULL, NULL, NULL, 0.00, 170.000, NULL, NULL, 400.000, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-24 19:15:55', '2024-09-26 21:39:58'),
(29, NULL, 2, 4, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, 'UV Set 6 watt Heron', NULL, NULL, NULL, 0.00, 1500.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-24 19:16:40', '2024-09-26 21:39:25'),
(30, NULL, 2, 4, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, 'Inline Big UF Filter Non Brand', NULL, NULL, NULL, 0.00, 500.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-24 19:17:34', '2024-09-26 21:39:08'),
(31, NULL, 2, 4, NULL, NULL, NULL, 14, 5, NULL, NULL, NULL, NULL, 'RO Male Elbow', NULL, NULL, NULL, 0.00, 20.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, 'Thread size 3/8\"  push size 3/8\'', NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-24 19:20:49', '2024-09-26 21:35:08'),
(32, NULL, 2, 4, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, 'Tap for RO machine', NULL, NULL, NULL, 0.00, 80.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-24 19:22:13', '2024-09-26 21:38:31'),
(33, NULL, 2, 4, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, 'Tap for RO machine', NULL, NULL, NULL, 0.00, 80.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-24 19:22:14', '2024-09-26 21:37:52'),
(34, NULL, 2, 4, NULL, NULL, NULL, 15, 5, NULL, NULL, NULL, NULL, '10mm Water connector Valve.', NULL, NULL, NULL, 0.00, 80.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-24 19:24:41', '2024-09-26 21:37:29'),
(35, NULL, 2, 4, NULL, 3, NULL, NULL, 5, NULL, NULL, NULL, NULL, 'Inline Big Post Carbon Filter', NULL, NULL, NULL, 0.00, 150.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-24 19:25:57', '2024-09-26 21:36:10'),
(36, NULL, 2, 4, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, 'Float Switch Electric', NULL, NULL, NULL, 0.00, 120.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-24 19:27:35', '2024-09-26 16:57:22'),
(37, NULL, 2, 2, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, 'RO Machine CT40', NULL, NULL, NULL, 0.00, 11000.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 0, 1, 1, '2024-09-26 22:45:44', '2024-09-26 22:48:51'),
(38, NULL, 2, 4, NULL, NULL, NULL, 16, 5, NULL, NULL, NULL, NULL, 'Non RO UV 5 Stage 20 Inch Machine Heron.', NULL, NULL, NULL, 0.00, 6000.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-26 22:48:41', '2024-09-26 22:48:41'),
(39, NULL, 2, 2, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, 'RO Machine 200 GPD Heron.', NULL, NULL, NULL, 0.00, 18000.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-26 22:49:55', '2024-09-26 22:49:55'),
(40, NULL, 2, 2, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, 'RO Machine Heron Zi White.', NULL, NULL, NULL, 0.00, 7000.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-26 22:53:14', '2024-09-26 22:53:14'),
(41, NULL, 2, 2, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, 'RO Machine Heron Max (Hot,Cold,Normal).', NULL, NULL, NULL, 0.00, 12000.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-26 22:54:57', '2024-09-26 22:54:57'),
(42, NULL, 2, 4, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, 'Auto Sensor For Water Storage Tank.', NULL, NULL, NULL, 0.00, 250.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-26 22:55:55', '2024-09-26 22:55:55'),
(43, NULL, 2, 4, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, 'O Ring for 10 Inch Housing.', NULL, NULL, NULL, 0.00, 10.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-26 22:56:49', '2024-09-26 22:56:49'),
(44, NULL, 2, 4, NULL, NULL, NULL, 15, 5, NULL, NULL, NULL, NULL, '10mm GDL Flow Tube White Roll.', NULL, NULL, NULL, 0.00, 1800.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-26 22:59:57', '2024-09-26 22:59:57'),
(45, NULL, 2, 4, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, 'Flow Restrictor ,Type-650CC.', NULL, NULL, NULL, 0.00, 50.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-26 23:01:10', '2024-09-26 23:01:10'),
(46, NULL, 2, 4, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, 'Water Storage Tank 6 Gallon.', NULL, NULL, NULL, 0.00, 2500.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-26 23:02:19', '2024-09-26 23:02:19'),
(47, NULL, 2, 1, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, 'UF Machine 100 GPD.', NULL, NULL, NULL, 0.00, 5000.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-26 23:03:26', '2024-09-26 23:03:26'),
(48, NULL, 2, 1, NULL, NULL, 4, NULL, 5, NULL, NULL, NULL, NULL, 'Booster Pump 75 GPD.', NULL, NULL, NULL, 0.00, 1400.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-26 23:04:34', '2024-09-26 23:04:34'),
(49, NULL, 2, 1, NULL, NULL, 4, NULL, 5, NULL, NULL, NULL, NULL, 'Booster Pump 75 GPD.', NULL, NULL, NULL, 0.00, 1400.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-26 23:04:35', '2024-09-26 23:04:35'),
(50, NULL, 2, 4, NULL, NULL, 4, NULL, 5, NULL, NULL, NULL, NULL, 'Booster Pump 100 GPD.', NULL, NULL, NULL, 0.00, 1500.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-26 23:05:19', '2024-09-26 23:59:44'),
(51, NULL, 2, 4, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, '10 Inch Clear Housing 1/2 GDL for iron Removal.', NULL, NULL, NULL, 0.00, 480.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-26 23:07:30', '2024-09-26 23:07:30'),
(52, NULL, 2, 4, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, 'Small American Faucet.', NULL, NULL, NULL, 0.00, 450.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-26 23:08:19', '2024-09-26 23:08:19'),
(53, NULL, 2, 4, NULL, 3, NULL, 17, 5, NULL, NULL, NULL, NULL, '20 Inch PP Filter.', NULL, NULL, NULL, 0.00, 70.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-26 23:12:58', '2024-09-26 23:12:58'),
(54, NULL, 2, 4, NULL, 3, 1, 19, 5, NULL, NULL, NULL, NULL, '20 Inch Big PP Filter ,Dot 680gm.', NULL, NULL, NULL, 0.00, 250.000, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-26 23:21:09', '2024-09-26 23:21:09'),
(55, NULL, 3, 6, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, 'Pay service', NULL, NULL, NULL, 0.00, NULL, NULL, NULL, 300.000, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 1, 1, 1, 1, '2024-09-28 17:04:00', '2024-09-28 17:04:48'),
(56, NULL, 3, 5, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, 'Free Service', NULL, NULL, NULL, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 1, 1, 1, 1, '2024-09-28 17:05:32', '2024-09-28 17:05:32'),
(57, NULL, 3, 6, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, 'Transport', NULL, NULL, NULL, 0.00, NULL, NULL, NULL, 200.000, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 1, 1, 1, 1, '2024-09-28 17:06:06', '2024-09-28 17:06:06'),
(58, NULL, 2, 4, NULL, NULL, NULL, NULL, 7, NULL, NULL, NULL, NULL, '10mm pipe', NULL, NULL, NULL, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 1, 1, 1, 1, '2024-09-28 17:15:33', '2024-09-28 17:15:33'),
(59, NULL, 2, 4, NULL, NULL, 1, 20, 7, NULL, NULL, NULL, NULL, '6mm Pipe.', NULL, NULL, NULL, 0.00, 4.500, NULL, NULL, 20.000, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 1, 1, 1, 1, '2024-09-28 17:37:12', '2024-10-17 23:43:48'),
(60, NULL, 2, 4, NULL, NULL, NULL, 16, 5, NULL, NULL, NULL, NULL, '20 Inch CTO', NULL, NULL, NULL, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-28 19:06:07', '2024-09-28 19:06:07'),
(61, NULL, 2, 4, NULL, NULL, NULL, 16, 5, NULL, NULL, NULL, NULL, '20 Inch GAC.', NULL, NULL, NULL, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-28 19:06:54', '2024-09-28 19:06:54'),
(62, NULL, 2, 4, NULL, NULL, NULL, 21, 5, NULL, NULL, NULL, NULL, '75 GPD Membrane', NULL, NULL, NULL, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-28 19:08:12', '2024-09-28 19:08:12'),
(63, NULL, 2, 4, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, 'Housing Wrench.', NULL, NULL, NULL, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-28 19:16:26', '2024-09-28 19:16:26'),
(64, NULL, 2, 2, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, 'Taste and Odor.', NULL, NULL, NULL, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-28 19:41:51', '2024-09-28 19:41:51'),
(65, NULL, 2, 2, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, 'Membrane Housing.', NULL, NULL, NULL, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 1, 1, 1, '2024-09-28 20:16:43', '2024-10-06 17:50:17'),
(66, NULL, 4, 7, NULL, NULL, NULL, NULL, 8, NULL, NULL, NULL, NULL, 'Conveyance', NULL, NULL, NULL, 0.00, 0.000, NULL, NULL, 300.000, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 0, 1, 0, 0, 1, 1, '2024-11-20 20:28:19', '2024-11-20 20:28:19'),
(67, NULL, 4, 7, NULL, NULL, NULL, NULL, 8, NULL, NULL, NULL, NULL, 'Outside Product', NULL, NULL, NULL, 0.00, 0.000, NULL, NULL, 500.000, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 0, 1, 0, 0, 1, 1, '2024-11-20 20:29:56', '2024-11-20 20:29:56'),
(68, NULL, 1, 3, NULL, 2, 1, 23, 5, NULL, NULL, NULL, NULL, 'Osmo Smart', NULL, NULL, NULL, 10.00, 8654.000, NULL, NULL, 11600.000, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, '0', 1, 1, 0, 0, 1, 1, '2024-11-27 20:58:52', '2024-11-27 20:58:52');

-- --------------------------------------------------------

--
-- Table structure for table `product_brands`
--

CREATE TABLE `product_brands` (
  `id` int(10) UNSIGNED NOT NULL,
  `brand_name` varchar(255) NOT NULL,
  `status` tinyint(4) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;

--
-- Dumping data for table `product_brands`
--

INSERT INTO `product_brands` (`id`, `brand_name`, `status`, `created_at`, `updated_at`) VALUES
(1, 'Osmo Direct Flow', 1, '2024-09-24 16:24:33', '2024-09-24 16:24:33'),
(2, 'Osmo reverse osmosis', 1, '2024-09-24 16:25:20', '2024-09-24 16:25:20'),
(3, 'Top Klean', 1, '2024-09-24 16:40:02', '2024-09-24 16:40:02');

-- --------------------------------------------------------

--
-- Table structure for table `product_categories`
--

CREATE TABLE `product_categories` (
  `id` int(10) UNSIGNED NOT NULL,
  `category_name` varchar(255) DEFAULT NULL,
  `slug` varchar(255) DEFAULT NULL,
  `order` varchar(255) DEFAULT '0',
  `status` int(11) DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `product_categories`
--

INSERT INTO `product_categories` (`id`, `category_name`, `slug`, `order`, `status`, `created_at`, `updated_at`) VALUES
(1, 'Direct FLow', NULL, '0', 1, '2024-09-11 12:49:42', '2024-09-24 16:22:59'),
(2, 'Reverse osmosis', NULL, '0', 1, '2024-09-12 05:29:32', '2024-09-24 16:23:26'),
(3, 'Box type reverse osmosis', NULL, '0', 1, '2024-09-24 16:23:54', '2024-09-24 16:23:54'),
(4, 'Accessories', NULL, '0', 1, '2024-09-24 16:38:13', '2024-09-24 16:38:13'),
(5, 'Free service', NULL, '0', 1, '2024-09-28 17:01:43', '2024-09-28 17:01:43'),
(6, 'pay service', NULL, '0', 1, '2024-09-28 17:02:05', '2024-09-28 17:02:05'),
(7, 'Product Service', NULL, '0', 1, '2024-11-20 20:25:34', '2024-11-20 20:25:34');

-- --------------------------------------------------------

--
-- Table structure for table `product_colors`
--

CREATE TABLE `product_colors` (
  `id` int(10) UNSIGNED NOT NULL,
  `color_name` varchar(255) NOT NULL,
  `status` tinyint(4) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;

--
-- Dumping data for table `product_colors`
--

INSERT INTO `product_colors` (`id`, `color_name`, `status`, `created_at`, `updated_at`) VALUES
(1, 'White', 1, '2024-04-27 00:39:34', '2024-04-27 00:39:34'),
(2, 'Golden', 1, '2024-04-27 00:41:10', '2024-04-27 00:41:10'),
(3, 'Pink', 1, '2024-04-27 00:41:16', '2024-04-27 00:41:16'),
(4, 'Black', 1, '2024-05-23 07:49:10', '2024-05-23 07:49:24'),
(5, 'Red', 1, '2024-06-10 12:17:34', '2024-06-10 12:17:34'),
(6, 'Yellow', 1, '2024-06-10 12:17:52', '2024-06-10 12:18:42'),
(7, 'Gray', 1, '2024-06-10 12:18:17', '2024-06-10 12:18:17'),
(8, 'Black', 1, '2024-09-24 18:45:36', '2024-09-24 18:45:36');

-- --------------------------------------------------------

--
-- Table structure for table `product_fragrances`
--

CREATE TABLE `product_fragrances` (
  `id` int(10) NOT NULL,
  `fragrance_name` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `status` int(11) DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `product_orders`
--

CREATE TABLE `product_orders` (
  `id` int(10) UNSIGNED NOT NULL,
  `customer_id` int(10) UNSIGNED DEFAULT NULL,
  `order_category` varchar(255) DEFAULT NULL,
  `order_type` varchar(255) DEFAULT NULL,
  `order_number` varchar(255) DEFAULT NULL,
  `manufacturer_article_no` varchar(255) DEFAULT NULL,
  `customer_article_no` varchar(255) DEFAULT NULL,
  `last_no` varchar(255) DEFAULT NULL,
  `description` longtext DEFAULT NULL,
  `remarks` longtext DEFAULT NULL,
  `order_date` timestamp NULL DEFAULT NULL,
  `delivery_date` timestamp NULL DEFAULT NULL,
  `status` int(4) DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `product_order_details`
--

CREATE TABLE `product_order_details` (
  `id` int(10) UNSIGNED NOT NULL,
  `product_order_id` int(10) UNSIGNED DEFAULT NULL,
  `image` varchar(255) DEFAULT NULL,
  `color` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `product_order_details_chains`
--

CREATE TABLE `product_order_details_chains` (
  `id` int(10) UNSIGNED NOT NULL,
  `product_order_details_id` int(10) UNSIGNED DEFAULT NULL,
  `size_id` int(10) UNSIGNED DEFAULT NULL,
  `quantity` int(10) DEFAULT 0,
  `unit_price` decimal(18,2) DEFAULT 0.00,
  `total_price` decimal(18,2) DEFAULT 0.00,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `product_services`
--

CREATE TABLE `product_services` (
  `id` int(11) NOT NULL,
  `invoice_no` varchar(255) DEFAULT NULL,
  `customer_id` int(11) DEFAULT NULL,
  `product_id` int(11) DEFAULT NULL,
  `service_type` varchar(100) DEFAULT NULL,
  `service_start_date` date DEFAULT NULL,
  `service_end_date` date DEFAULT NULL,
  `service_quantity` int(11) DEFAULT NULL,
  `service_description` text DEFAULT NULL,
  `service_location` text DEFAULT NULL,
  `done_by` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `product_service_details`
--

CREATE TABLE `product_service_details` (
  `id` int(11) NOT NULL,
  `product_service_id` int(11) NOT NULL,
  `service_invoice` varchar(255) DEFAULT NULL,
  `service_date` date NOT NULL,
  `actual_service_date` date DEFAULT NULL,
  `service_number` int(11) NOT NULL,
  `service_man_name` varchar(100) DEFAULT NULL,
  `service_man_mobile` varchar(20) DEFAULT NULL,
  `remarks` text DEFAULT NULL,
  `service_status` int(11) DEFAULT 0,
  `done_by` varchar(100) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `product_sizes`
--

CREATE TABLE `product_sizes` (
  `id` int(10) UNSIGNED NOT NULL,
  `size_name` varchar(255) NOT NULL,
  `status` tinyint(4) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;

--
-- Dumping data for table `product_sizes`
--

INSERT INTO `product_sizes` (`id`, `size_name`, `status`, `created_at`, `updated_at`) VALUES
(1, '110 gm', 1, '2024-09-24 16:51:37', '2024-09-24 16:51:37'),
(2, '10 Inch', 1, '2024-09-24 18:08:42', '2024-09-24 18:08:42'),
(3, 'Small', 1, '2024-09-24 18:16:00', '2024-09-24 18:16:00'),
(4, 'Small', 1, '2024-09-24 18:16:01', '2024-09-24 18:16:01'),
(5, 'Big', 1, '2024-09-24 18:21:50', '2024-09-24 18:21:50'),
(6, 'Big', 1, '2024-09-24 18:21:50', '2024-09-24 18:21:50'),
(7, '1/4*1/4\"', 1, '2024-09-24 18:27:08', '2024-09-24 18:27:08'),
(8, 'pcs', 1, '2024-09-24 18:28:44', '2024-09-24 18:28:44'),
(9, '6mm', 1, '2024-09-24 18:34:01', '2024-09-24 18:34:01'),
(10, '28*28*36CM', 1, '2024-09-24 18:51:15', '2024-09-24 18:51:15'),
(11, '28*28*36CM', 1, '2024-09-24 18:51:16', '2024-09-24 18:51:16'),
(12, '100 GPD', 1, '2024-09-24 19:01:34', '2024-09-24 19:01:34'),
(13, '200 GPD', 1, '2024-09-24 19:08:52', '2024-09-24 19:08:52'),
(14, '3/8*3/8\"', 1, '2024-09-24 19:19:08', '2024-09-24 19:19:08'),
(15, '10mm', 1, '2024-09-24 19:22:40', '2024-09-24 19:22:40'),
(16, '20 Inch', 1, '2024-09-26 22:46:37', '2024-09-26 22:46:37'),
(17, 'Dot 220gm.', 1, '2024-09-26 23:10:42', '2024-09-26 23:10:42'),
(18, 'Dot 680gm', 1, '2024-09-26 23:18:37', '2024-09-26 23:18:37'),
(19, 'Dot 680gm', 1, '2024-09-26 23:18:37', '2024-09-26 23:18:37'),
(20, '6mm', 1, '2024-09-28 17:35:40', '2024-09-28 17:35:40'),
(21, '75 GPD', 1, '2024-09-28 19:07:33', '2024-09-28 19:07:33'),
(22, 'Osmo Smart', 1, '2024-11-27 20:53:17', '2024-11-27 20:53:17'),
(23, '40*20.5*51 cm', 1, '2024-11-27 20:54:24', '2024-11-27 20:54:24');

-- --------------------------------------------------------

--
-- Table structure for table `product_sub_categories`
--

CREATE TABLE `product_sub_categories` (
  `id` int(10) UNSIGNED NOT NULL,
  `category_id` int(10) UNSIGNED NOT NULL,
  `sub_category_name` varchar(255) DEFAULT NULL,
  `slug` varchar(255) DEFAULT NULL,
  `order` varchar(255) DEFAULT '0',
  `status` int(11) DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;

-- --------------------------------------------------------

--
-- Table structure for table `product_types`
--

CREATE TABLE `product_types` (
  `id` int(10) NOT NULL,
  `type_name` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `status` int(11) DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `product_types`
--

INSERT INTO `product_types` (`id`, `type_name`, `status`, `created_at`, `updated_at`) VALUES
(1, 'Finish Goods', 1, '2024-09-11 12:49:11', '2024-09-11 12:49:11'),
(2, 'Raw Material', 1, '2024-09-11 12:49:22', '2024-09-11 12:49:22'),
(3, 'Service', 1, '2024-09-28 17:00:27', '2024-09-28 17:00:27'),
(4, 'Service Item', 1, '2024-11-20 20:24:56', '2024-11-20 20:24:56');

-- --------------------------------------------------------

--
-- Table structure for table `product_units`
--

CREATE TABLE `product_units` (
  `id` int(10) UNSIGNED NOT NULL,
  `unit_name` varchar(255) NOT NULL,
  `unit_value` varchar(255) DEFAULT NULL,
  `status` tinyint(4) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;

--
-- Dumping data for table `product_units`
--

INSERT INTO `product_units` (`id`, `unit_name`, `unit_value`, `status`, `created_at`, `updated_at`) VALUES
(1, 'kg', '1', 1, '2024-09-11 12:50:07', '2024-09-11 12:50:07'),
(2, 'ml', '1', 1, '2024-09-12 05:29:42', '2024-09-12 05:29:42'),
(3, 'Ro-105', '1', 1, '2024-09-17 21:57:02', '2024-09-17 21:57:02'),
(4, 'DF', '1', 1, '2024-09-17 22:08:47', '2024-09-17 22:08:47'),
(5, 'pcs', '1', 1, '2024-09-17 22:09:39', '2024-09-24 16:26:20'),
(6, '10mm pipe', '10', 1, '2024-09-28 17:13:46', '2024-09-28 17:13:46'),
(7, 'feet', '10', 1, '2024-09-28 17:14:44', '2024-09-28 17:14:44'),
(8, 'One Time', '1', 1, '2024-11-20 20:26:22', '2024-11-20 20:26:22');

-- --------------------------------------------------------

--
-- Table structure for table `promotions`
--

CREATE TABLE `promotions` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `employee_id` int(11) NOT NULL DEFAULT 0,
  `branch_id` int(11) DEFAULT NULL,
  `department_id` int(11) DEFAULT NULL,
  `designation_id` int(11) NOT NULL DEFAULT 0,
  `start_date` date NOT NULL,
  `end_date` date DEFAULT NULL,
  `description` varchar(191) DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `promotions`
--

INSERT INTO `promotions` (`id`, `employee_id`, `branch_id`, `department_id`, `designation_id`, `start_date`, `end_date`, `description`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 1, 2, 4, 1, '2024-01-01', NULL, '', 1, '2024-01-21 03:21:27', '2024-01-21 03:21:27');

-- --------------------------------------------------------

--
-- Table structure for table `requisitions`
--

CREATE TABLE `requisitions` (
  `id` int(10) UNSIGNED NOT NULL,
  `stock_date` datetime DEFAULT NULL,
  `stock_type` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `invoice_no` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `product_id` int(10) UNSIGNED DEFAULT NULL,
  `purchase_price` decimal(18,2) DEFAULT 0.00,
  `stock_in_quantity` decimal(18,2) DEFAULT 0.00,
  `stock_in_unit_price` decimal(18,2) DEFAULT 0.00,
  `stock_in_discount` decimal(18,2) DEFAULT 0.00,
  `stock_in_total_amount` decimal(18,2) DEFAULT 0.00,
  `stock_out_quantity` decimal(18,2) DEFAULT 0.00,
  `stock_out_unit_price` decimal(18,2) DEFAULT 0.00,
  `stock_out_discount` decimal(18,2) DEFAULT 0.00,
  `stock_out_total_amount` decimal(18,2) DEFAULT 0.00,
  `done_by` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `remarks` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `status` tinyint(10) DEFAULT 0,
  `approved_level` int(11) DEFAULT 3,
  `read_at` int(11) DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `resignations`
--

CREATE TABLE `resignations` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `employee_id` int(11) NOT NULL DEFAULT 0,
  `notice_date` date NOT NULL,
  `resignation_date` date NOT NULL,
  `last_working_date` date NOT NULL,
  `description` varchar(191) DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `resignations`
--

INSERT INTO `resignations` (`id`, `employee_id`, `notice_date`, `resignation_date`, `last_working_date`, `description`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 1, '2023-09-04', '2023-10-01', '2023-09-30', 'dgdfgfdgfdgf', 1, '2023-09-03 23:55:24', '2023-09-03 23:55:24');

-- --------------------------------------------------------

--
-- Table structure for table `roles`
--

CREATE TABLE `roles` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(191) NOT NULL,
  `guard_name` varchar(191) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `roles`
--

INSERT INTO `roles` (`id`, `name`, `guard_name`, `created_at`, `updated_at`) VALUES
(1, 'administrator', 'web', '2023-07-25 04:29:52', '2023-08-01 02:53:54'),
(2, 'developer', 'web', '2023-07-25 04:29:54', '2023-07-25 04:29:54'),
(3, 'employee', 'web', '2023-07-25 04:50:46', '2023-07-25 04:50:46'),
(7, 'HR', 'web', '2023-09-20 01:07:53', '2023-11-07 03:38:01'),
(8, 'Chemist', 'web', '2024-05-14 11:45:21', '2024-05-14 11:45:21'),
(9, 'Production Manager', 'web', '2024-05-14 11:45:58', '2024-05-14 11:45:58'),
(10, 'Store Incharge', 'web', '2024-05-14 11:46:30', '2024-05-14 11:46:54'),
(11, 'CEO/MD', 'web', '2024-05-16 08:34:36', '2024-05-16 08:34:36'),
(12, 'Jago Admin', 'web', '2024-09-12 05:15:22', '2024-09-12 05:15:22');

-- --------------------------------------------------------

--
-- Table structure for table `role_has_permissions`
--

CREATE TABLE `role_has_permissions` (
  `permission_id` bigint(20) UNSIGNED NOT NULL,
  `role_id` bigint(20) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `role_has_permissions`
--

INSERT INTO `role_has_permissions` (`permission_id`, `role_id`) VALUES
(1, 1),
(1, 2),
(2, 1),
(2, 2),
(3, 1),
(3, 2),
(4, 1),
(4, 2),
(5, 1),
(5, 2),
(6, 1),
(6, 2),
(7, 1),
(7, 2),
(8, 1),
(8, 2),
(9, 1),
(9, 2),
(10, 1),
(10, 2),
(11, 1),
(11, 2),
(12, 1),
(12, 2),
(13, 1),
(13, 2),
(14, 1),
(14, 2),
(15, 1),
(15, 2),
(16, 1),
(16, 2),
(17, 1),
(17, 2),
(18, 1),
(18, 2),
(19, 1),
(19, 2),
(20, 1),
(20, 2),
(21, 1),
(21, 2),
(22, 1),
(22, 2),
(23, 1),
(23, 2),
(24, 1),
(24, 2),
(25, 1),
(25, 2),
(26, 1),
(26, 2),
(27, 1),
(27, 2),
(40, 1),
(40, 2),
(41, 1),
(41, 2),
(42, 1),
(42, 2),
(49, 1),
(49, 2),
(49, 7),
(50, 1),
(50, 2),
(50, 7),
(51, 1),
(51, 2),
(51, 7),
(52, 1),
(52, 2),
(52, 7),
(53, 1),
(53, 2),
(53, 7),
(54, 1),
(54, 2),
(54, 7),
(55, 1),
(55, 2),
(55, 3),
(55, 7),
(56, 1),
(56, 2),
(56, 3),
(56, 7),
(57, 1),
(57, 2),
(57, 3),
(57, 7),
(73, 1),
(73, 2),
(73, 7),
(74, 1),
(74, 2),
(74, 7),
(80, 1),
(80, 2),
(80, 7),
(81, 1),
(81, 2),
(81, 7),
(82, 1),
(82, 2),
(82, 3),
(82, 7),
(83, 1),
(83, 2),
(83, 3),
(83, 7),
(86, 1),
(86, 2),
(86, 7),
(87, 1),
(87, 2),
(87, 7),
(90, 1),
(90, 2),
(91, 1),
(91, 2),
(93, 1),
(93, 2),
(94, 1),
(94, 2),
(95, 1),
(95, 2),
(95, 7),
(96, 1),
(96, 2),
(96, 7),
(97, 1),
(97, 2),
(97, 7),
(99, 1),
(99, 2),
(100, 1),
(100, 2),
(101, 1),
(101, 2),
(102, 1),
(102, 2),
(103, 1),
(103, 2),
(104, 1),
(104, 2),
(109, 1),
(109, 2),
(110, 1),
(110, 2),
(111, 1),
(111, 2),
(112, 1),
(112, 2),
(113, 1),
(113, 2),
(114, 1),
(114, 2),
(115, 1),
(115, 2),
(116, 1),
(116, 2),
(117, 1),
(117, 2),
(118, 1),
(118, 2),
(119, 1),
(119, 2),
(120, 1),
(120, 2),
(121, 1),
(121, 2),
(122, 1),
(122, 2),
(123, 1),
(123, 2),
(124, 1),
(124, 2),
(125, 1),
(125, 2),
(126, 1),
(126, 2),
(127, 1),
(127, 2),
(128, 1),
(128, 2),
(129, 1),
(129, 2),
(131, 1),
(131, 2),
(132, 1),
(132, 2),
(133, 1),
(133, 2),
(134, 1),
(134, 2),
(134, 3),
(135, 1),
(135, 2),
(135, 3),
(136, 1),
(136, 2),
(137, 1),
(137, 2),
(137, 7),
(138, 1),
(138, 2),
(138, 7),
(139, 1),
(139, 2),
(139, 7),
(140, 1),
(140, 2),
(141, 1),
(141, 2),
(142, 1),
(142, 2),
(143, 1),
(143, 2),
(144, 1),
(144, 2),
(145, 1),
(145, 2),
(153, 1),
(153, 3),
(153, 7),
(154, 1),
(154, 7),
(155, 1),
(155, 7),
(156, 1),
(157, 1),
(158, 1),
(159, 1),
(160, 1),
(161, 1),
(162, 1),
(162, 7),
(163, 1),
(163, 7),
(164, 1),
(164, 7),
(165, 1),
(165, 7),
(166, 1),
(166, 7),
(167, 1),
(167, 7),
(168, 1),
(168, 7),
(168, 12),
(169, 1),
(169, 7),
(169, 12),
(170, 1),
(170, 7),
(170, 12),
(171, 1),
(171, 7),
(172, 1),
(172, 7),
(173, 1),
(173, 7),
(174, 1),
(174, 7),
(174, 12),
(175, 1),
(175, 7),
(175, 12),
(176, 1),
(176, 7),
(176, 12),
(177, 1),
(177, 7),
(178, 1),
(178, 7),
(179, 1),
(179, 7),
(180, 1),
(180, 7),
(180, 10),
(180, 12),
(181, 1),
(181, 7),
(181, 10),
(181, 12),
(182, 1),
(182, 7),
(182, 10),
(182, 12),
(183, 1),
(183, 7),
(183, 10),
(183, 12),
(184, 1),
(184, 7),
(184, 10),
(184, 12),
(185, 1),
(185, 7),
(185, 10),
(185, 12),
(186, 1),
(186, 7),
(186, 10),
(186, 12),
(187, 1),
(187, 7),
(187, 10),
(187, 12),
(188, 1),
(188, 7),
(188, 10),
(188, 12),
(189, 1),
(189, 7),
(189, 10),
(189, 12),
(190, 1),
(190, 7),
(190, 10),
(190, 12),
(191, 1),
(191, 7),
(191, 10),
(191, 12),
(192, 1),
(192, 7),
(192, 10),
(192, 12),
(193, 1),
(193, 7),
(193, 10),
(193, 12),
(194, 1),
(194, 7),
(194, 10),
(194, 12),
(195, 1),
(195, 7),
(195, 10),
(195, 12),
(196, 1),
(196, 7),
(196, 10),
(196, 12),
(197, 1),
(197, 7),
(197, 10),
(197, 12),
(198, 1),
(198, 7),
(198, 10),
(198, 12),
(199, 1),
(199, 7),
(199, 10),
(199, 12),
(200, 1),
(200, 7),
(200, 10),
(200, 12),
(201, 1),
(201, 7),
(201, 10),
(201, 12),
(202, 1),
(202, 7),
(202, 10),
(202, 12),
(203, 1),
(203, 7),
(203, 10),
(203, 12),
(204, 1),
(204, 7),
(204, 10),
(204, 12),
(205, 1),
(205, 7),
(205, 10),
(205, 12),
(206, 1),
(206, 7),
(206, 10),
(206, 12),
(207, 1),
(207, 7),
(207, 10),
(207, 12),
(208, 1),
(208, 7),
(208, 10),
(208, 12),
(209, 1),
(209, 7),
(209, 10),
(209, 12),
(210, 1),
(210, 7),
(210, 8),
(210, 10),
(210, 12),
(211, 1),
(211, 7),
(212, 1),
(212, 7),
(213, 1),
(213, 7),
(214, 1),
(214, 7),
(215, 1),
(215, 7),
(216, 1),
(216, 7),
(220, 1),
(220, 7),
(221, 1),
(221, 7),
(222, 1),
(222, 7),
(223, 1),
(223, 7),
(224, 1),
(224, 7),
(225, 1),
(225, 7),
(226, 1),
(226, 7),
(227, 1),
(227, 7),
(228, 1),
(228, 7),
(229, 1),
(229, 7),
(229, 12),
(230, 1),
(230, 7),
(230, 12),
(231, 1),
(231, 7),
(231, 12),
(232, 1),
(232, 8),
(232, 12),
(233, 1),
(233, 8),
(233, 12),
(234, 1),
(234, 8),
(234, 12),
(235, 1),
(235, 12),
(236, 1),
(236, 12),
(237, 1),
(237, 12),
(238, 1),
(238, 8),
(238, 12),
(239, 1),
(239, 8),
(239, 12),
(240, 1),
(240, 8),
(240, 12),
(241, 1),
(241, 10),
(241, 12),
(242, 1),
(242, 10),
(242, 12),
(243, 1),
(243, 10),
(243, 12),
(244, 1),
(244, 10),
(244, 12),
(245, 1),
(245, 10),
(245, 12),
(246, 1),
(246, 10),
(246, 12),
(247, 1),
(247, 10),
(248, 1),
(248, 10),
(249, 1),
(249, 10),
(250, 1),
(250, 12),
(251, 1),
(251, 12),
(252, 1),
(252, 12),
(253, 1),
(253, 12),
(254, 1),
(254, 8),
(254, 11),
(254, 12),
(255, 1),
(255, 8),
(255, 12),
(256, 1),
(256, 8),
(256, 12),
(257, 1),
(257, 8),
(257, 9),
(257, 10),
(257, 11),
(257, 12),
(258, 1),
(258, 8),
(258, 9),
(258, 10),
(258, 11),
(258, 12),
(259, 1),
(259, 12),
(260, 1),
(260, 12),
(261, 1),
(261, 12),
(262, 1),
(262, 11),
(262, 12),
(263, 1),
(263, 11),
(263, 12),
(264, 1),
(264, 11),
(264, 12),
(265, 1),
(265, 12),
(266, 1),
(266, 12),
(267, 1),
(267, 12),
(268, 1),
(268, 12),
(269, 1),
(269, 12),
(270, 1),
(270, 12),
(271, 1),
(271, 12),
(272, 1),
(272, 12),
(273, 1),
(273, 12),
(274, 1),
(274, 12),
(275, 1),
(275, 12),
(276, 1),
(276, 12),
(277, 1),
(277, 12),
(278, 1),
(278, 12),
(279, 1),
(279, 12),
(280, 1),
(280, 12),
(284, 1),
(284, 12),
(285, 1),
(285, 12),
(286, 1),
(286, 12),
(288, 1),
(288, 12),
(289, 1),
(289, 12),
(290, 1),
(290, 12),
(291, 1),
(291, 12),
(292, 1),
(292, 12),
(293, 1),
(293, 12),
(294, 1),
(294, 12),
(295, 1),
(295, 12),
(296, 1),
(296, 12),
(297, 1),
(297, 12);

-- --------------------------------------------------------

--
-- Table structure for table `salary_sections`
--

CREATE TABLE `salary_sections` (
  `id` int(11) NOT NULL DEFAULT 0,
  `type_name` varchar(150) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `type_name_bangla` varchar(150) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `status` int(11) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `set_salaries`
--

CREATE TABLE `set_salaries` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;

-- --------------------------------------------------------

--
-- Table structure for table `stocks`
--

CREATE TABLE `stocks` (
  `id` int(11) UNSIGNED NOT NULL,
  `warehouse_id` int(11) DEFAULT 1,
  `to_warehouse_id` int(11) DEFAULT 0,
  `stock_date` datetime DEFAULT NULL,
  `stock_type` varchar(255) DEFAULT NULL,
  `delivery_challan_no` varchar(200) DEFAULT NULL,
  `invoice_no` varchar(255) DEFAULT NULL,
  `product_id` int(11) UNSIGNED DEFAULT NULL,
  `supplier_id` int(11) UNSIGNED DEFAULT NULL,
  `supplier_invoice_no` varchar(255) DEFAULT NULL,
  `purchase_price` decimal(18,2) DEFAULT 0.00,
  `stock_in_quantity` decimal(18,2) DEFAULT 0.00,
  `stock_in_unit_price` decimal(18,2) DEFAULT 0.00,
  `stock_in_discount` decimal(18,2) DEFAULT 0.00,
  `stock_in_total_amount` decimal(20,2) DEFAULT 0.00,
  `customer_id` int(11) UNSIGNED DEFAULT NULL,
  `stock_out_quantity` decimal(18,2) DEFAULT 0.00,
  `stock_out_unit_price` decimal(18,2) DEFAULT 0.00,
  `stock_out_discount` decimal(18,2) DEFAULT 0.00,
  `stock_out_total_amount` decimal(20,2) DEFAULT 0.00,
  `done_by` varchar(100) DEFAULT NULL,
  `remarks` varchar(255) DEFAULT NULL,
  `status` tinyint(10) DEFAULT 1,
  `product_service_detail_id` int(11) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `stocks`
--

INSERT INTO `stocks` (`id`, `warehouse_id`, `to_warehouse_id`, `stock_date`, `stock_type`, `delivery_challan_no`, `invoice_no`, `product_id`, `supplier_id`, `supplier_invoice_no`, `purchase_price`, `stock_in_quantity`, `stock_in_unit_price`, `stock_in_discount`, `stock_in_total_amount`, `customer_id`, `stock_out_quantity`, `stock_out_unit_price`, `stock_out_discount`, `stock_out_total_amount`, `done_by`, `remarks`, `status`, `product_service_detail_id`, `created_at`, `updated_at`) VALUES
(6, 1, 0, '2024-04-02 00:00:00', 'Out', 'CHA000001', 'INV000001', 4, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 113, 1.00, 4000.00, NULL, 4000.00, 'Admin', NULL, 0, NULL, '2024-09-24 17:19:55', '2024-09-24 17:19:55'),
(217, 1, 0, '2024-04-06 00:00:00', 'Out', 'CHA000005', 'INV000005', 3, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 114, 1.00, 10900.00, 1400.00, 9500.00, 'Admin', NULL, 0, NULL, '2024-10-01 14:59:58', '2024-10-01 14:59:58'),
(224, 1, 0, '2024-04-29 00:00:00', 'Out', 'CHA000008', 'INV000008', 3, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 118, 1.00, 11500.00, 2000.00, 9500.00, 'Admin', NULL, 0, NULL, '2024-10-01 15:16:06', '2024-10-01 15:16:06'),
(225, 1, 0, '2024-04-29 00:00:00', 'Out', 'CHA000008', 'INV000008', 59, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 118, 25.00, 10.00, 0.00, 250.00, 'Admin', NULL, 0, NULL, '2024-10-01 15:16:06', '2024-10-01 15:16:06'),
(226, 1, 0, '2024-04-25 00:00:00', 'Out', 'CHA000007', 'INV000007', 3, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 117, 1.00, 11500.00, 0.00, 11500.00, 'Admin', NULL, 0, NULL, '2024-10-01 15:16:52', '2024-10-01 15:16:52'),
(227, 1, 0, '2024-04-25 00:00:00', 'Out', 'CHA000007', 'INV000007', 59, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 117, 40.00, 10.00, 0.00, 400.00, 'Admin', NULL, 0, NULL, '2024-10-01 15:16:52', '2024-10-01 15:16:52'),
(230, 1, 0, '2024-04-30 00:00:00', 'Out', 'CHA000009', 'INV000009', 3, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 119, 1.00, 11500.00, 2000.00, 9500.00, 'Admin', NULL, 0, NULL, '2024-10-01 15:24:34', '2024-10-01 15:24:34'),
(231, 1, 0, '2024-04-23 00:00:00', 'Out', 'CHA000010', 'INV000010', 4, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 120, 2.00, 4000.00, 0.00, 8000.00, 'Admin', NULL, 0, NULL, '2024-10-01 15:26:00', '2024-10-01 15:26:00'),
(233, 1, 0, '2024-05-06 00:00:00', 'Out', 'CHA000012', 'INV000012', 3, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 122, 1.00, 11500.00, 2000.00, 9500.00, 'Admin', NULL, 0, NULL, '2024-10-01 15:29:35', '2024-10-01 15:29:35'),
(234, 1, 0, '2024-05-06 00:00:00', 'Out', 'CHA000012', 'INV000012', 59, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 122, 10.00, 10.00, 0.00, 100.00, 'Admin', NULL, 0, NULL, '2024-10-01 15:29:35', '2024-10-01 15:29:35'),
(235, 1, 0, '2024-05-07 00:00:00', 'Out', 'CHA000013', 'INV000013', 3, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 123, 1.00, 11500.00, 2000.00, 9500.00, 'Admin', NULL, 0, NULL, '2024-10-01 16:27:43', '2024-10-01 16:27:43'),
(236, 1, 0, '2024-05-07 00:00:00', 'Out', 'CHA000013', 'INV000013', 59, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 123, 10.00, 10.00, 0.00, 100.00, 'Admin', NULL, 0, NULL, '2024-10-01 16:27:43', '2024-10-01 16:27:43'),
(237, 1, 0, '2024-05-08 00:00:00', 'Out', 'CHA000014', 'INV000014', 4, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 124, 1.00, 5000.00, 1000.00, 4000.00, 'Admin', NULL, 0, NULL, '2024-10-01 16:29:58', '2024-10-01 16:29:58'),
(238, 1, 0, '2024-05-08 00:00:00', 'Out', 'CHA000015', 'INV000015', 3, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 125, 1.00, 11500.00, 2000.00, 9500.00, 'Admin', NULL, 0, NULL, '2024-10-01 16:33:39', '2024-10-01 16:33:39'),
(239, 1, 0, '2024-05-09 00:00:00', 'Out', 'CHA000016', 'INV000016', 3, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 126, 1.00, 11500.00, 2000.00, 9500.00, 'Admin', NULL, 0, NULL, '2024-10-01 16:35:15', '2024-10-01 16:35:15'),
(240, 1, 0, '2024-05-09 00:00:00', 'Out', 'CHA000016', 'INV000016', 59, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 126, 20.00, 10.00, 0.00, 200.00, 'Admin', NULL, 0, NULL, '2024-10-01 16:35:15', '2024-10-01 16:35:15'),
(241, 1, 0, '2024-05-12 00:00:00', 'Out', 'CHA000017', 'INV000017', 3, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 120, 1.00, 11500.00, 2350.00, 9150.00, 'Admin', NULL, 0, NULL, '2024-10-01 16:36:53', '2024-10-01 16:36:53'),
(242, 1, 0, '2024-05-13 00:00:00', 'Out', 'CHA000018', 'INV000018', 3, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 128, 1.00, 11500.00, 2000.00, 9500.00, 'Admin', NULL, 0, NULL, '2024-10-01 16:38:26', '2024-10-01 16:38:26'),
(243, 1, 0, '2024-05-16 00:00:00', 'Out', 'CHA000019', 'INV000019', 6, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 129, 1.00, 200.00, 0.00, 200.00, 'Admin', NULL, 0, NULL, '2024-10-01 16:39:34', '2024-10-01 16:39:34'),
(244, 1, 0, '2024-05-16 00:00:00', 'Out', 'CHA000019', 'INV000019', 55, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 129, 1.00, 400.00, 100.00, 300.00, 'Admin', NULL, 0, NULL, '2024-10-01 16:39:34', '2024-10-01 16:39:34'),
(245, 1, 0, '2024-05-20 00:00:00', 'Out', 'CHA000020', 'INV000020', 3, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 130, 1.00, 11500.00, 2500.00, 9000.00, 'Admin', NULL, 0, NULL, '2024-10-01 16:41:42', '2024-10-01 16:41:42'),
(246, 1, 0, '2024-05-20 00:00:00', 'Out', 'CHA000020', 'INV000020', 59, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 130, 15.00, 10.00, 0.00, 150.00, 'Admin', NULL, 0, NULL, '2024-10-01 16:41:42', '2024-10-01 16:41:42'),
(247, 1, 0, '2024-05-15 00:00:00', 'Out', 'CHA000022', 'INV000022', 53, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 142, 1.00, 240.00, 0.00, 240.00, 'Admin', NULL, 0, NULL, '2024-10-01 16:51:45', '2024-10-01 16:51:45'),
(248, 1, 0, '2024-05-15 00:00:00', 'Out', 'CHA000022', 'INV000022', 60, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 142, 1.00, 350.00, 0.00, 350.00, 'Admin', NULL, 0, NULL, '2024-10-01 16:51:45', '2024-10-01 16:51:45'),
(249, 1, 0, '2024-05-15 00:00:00', 'Out', 'CHA000022', 'INV000022', 61, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 142, 1.00, 350.00, 0.00, 350.00, 'Admin', NULL, 0, NULL, '2024-10-01 16:51:45', '2024-10-01 16:51:45'),
(250, 1, 0, '2024-05-15 00:00:00', 'Out', 'CHA000022', 'INV000022', 62, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 142, 2.00, 1850.00, 0.00, 3700.00, 'Admin', NULL, 0, NULL, '2024-10-01 16:51:45', '2024-10-01 16:51:45'),
(251, 1, 0, '2024-05-15 00:00:00', 'Out', 'CHA000022', 'INV000022', 55, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 142, 1.00, 300.00, 0.00, 300.00, 'Admin', NULL, 0, NULL, '2024-10-01 16:51:45', '2024-10-01 16:51:45'),
(252, 1, 0, '2024-05-16 00:00:00', 'Out', 'CHA000021', 'INV000021', 6, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 142, 1.00, 120.00, 0.00, 120.00, 'Admin', NULL, 0, NULL, '2024-10-01 16:52:41', '2024-10-01 16:52:41'),
(253, 1, 0, '2024-05-16 00:00:00', 'Out', 'CHA000021', 'INV000021', 7, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 142, 1.00, 250.00, 0.00, 250.00, 'Admin', NULL, 0, NULL, '2024-10-01 16:52:41', '2024-10-01 16:52:41'),
(254, 1, 0, '2024-05-16 00:00:00', 'Out', 'CHA000021', 'INV000021', 8, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 142, 1.00, 250.00, 0.00, 250.00, 'Admin', NULL, 0, NULL, '2024-10-01 16:52:41', '2024-10-01 16:52:41'),
(255, 1, 0, '2024-05-16 00:00:00', 'Out', 'CHA000021', 'INV000021', 55, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 142, 1.00, 300.00, 0.00, 300.00, 'Admin', NULL, 0, NULL, '2024-10-01 16:52:41', '2024-10-01 16:52:41'),
(256, 1, 0, '2024-05-30 00:00:00', 'Out', 'CHA000023', 'INV000023', 6, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 131, 1.00, 120.00, 0.00, 120.00, 'Admin', NULL, 0, NULL, '2024-10-01 16:58:10', '2024-10-01 16:58:10'),
(257, 1, 0, '2024-05-30 00:00:00', 'Out', 'CHA000023', 'INV000023', 8, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 131, 1.00, 250.00, 0.00, 250.00, 'Admin', NULL, 0, NULL, '2024-10-01 16:58:10', '2024-10-01 16:58:10'),
(258, 1, 0, '2024-05-30 00:00:00', 'Out', 'CHA000023', 'INV000023', 7, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 131, 1.00, 250.00, 0.00, 250.00, 'Admin', NULL, 0, NULL, '2024-10-01 16:58:10', '2024-10-01 16:58:10'),
(259, 1, 0, '2024-05-30 00:00:00', 'Out', 'CHA000023', 'INV000023', 55, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 131, 1.00, 300.00, 0.00, 300.00, 'Admin', NULL, 0, NULL, '2024-10-01 16:58:10', '2024-10-01 16:58:10'),
(260, 1, 0, '2024-05-30 00:00:00', 'Out', 'CHA000024', 'INV000024', 63, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 131, 1.00, 100.00, 0.00, 100.00, 'Admin', NULL, 0, NULL, '2024-10-01 16:58:44', '2024-10-01 16:58:44'),
(261, 1, 0, '2024-06-01 00:00:00', 'Out', 'CHA000025', 'INV000025', 3, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 132, 1.00, 11500.00, 2000.00, 9500.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:02:14', '2024-10-01 17:02:14'),
(262, 1, 0, '2024-06-01 00:00:00', 'Out', 'CHA000025', 'INV000025', 27, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 132, 1.00, 500.00, 0.00, 500.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:02:14', '2024-10-01 17:02:14'),
(272, 1, 0, '2024-06-03 00:00:00', 'Out', 'CHA000026', 'INV000026', 7, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 135, 1.00, 250.00, 0.00, 250.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:14:29', '2024-10-01 17:14:29'),
(273, 1, 0, '2024-06-03 00:00:00', 'Out', 'CHA000026', 'INV000026', 8, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 135, 1.00, 250.00, 0.00, 250.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:14:29', '2024-10-01 17:14:29'),
(274, 1, 0, '2024-06-03 00:00:00', 'Out', 'CHA000026', 'INV000026', 62, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 135, 1.00, 1750.00, 0.00, 1750.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:14:29', '2024-10-01 17:14:29'),
(275, 1, 0, '2024-06-03 00:00:00', 'Out', 'CHA000026', 'INV000026', 27, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 135, 1.00, 450.00, 0.00, 450.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:14:29', '2024-10-01 17:14:29'),
(276, 1, 0, '2024-06-03 00:00:00', 'Out', 'CHA000026', 'INV000026', 59, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 135, 12.00, 10.00, 0.00, 120.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:14:29', '2024-10-01 17:14:29'),
(277, 1, 0, '2024-06-03 00:00:00', 'Out', 'CHA000026', 'INV000026', 64, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 135, 1.00, 450.00, 0.00, 450.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:14:29', '2024-10-01 17:14:29'),
(278, 1, 0, '2024-06-03 00:00:00', 'Out', 'CHA000026', 'INV000026', 57, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 135, 1.00, 300.00, 0.00, 300.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:14:29', '2024-10-01 17:14:29'),
(279, 1, 0, '2024-06-03 00:00:00', 'Out', 'CHA000026', 'INV000026', 55, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 135, 1.00, 500.00, 0.00, 500.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:14:29', '2024-10-01 17:14:29'),
(280, 1, 0, '2024-06-03 00:00:00', 'Out', 'CHA000026', 'INV000026', 6, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 135, 2.00, 120.00, 0.00, 240.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:14:29', '2024-10-01 17:14:29'),
(281, 1, 0, '2024-06-04 00:00:00', 'Out', 'CHA000027', 'INV000027', 15, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 136, 1.00, 550.00, 0.00, 550.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:15:54', '2024-10-01 17:15:54'),
(282, 1, 0, '2024-06-04 00:00:00', 'Out', 'CHA000027', 'INV000027', 55, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 136, 1.00, 600.00, 0.00, 600.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:15:54', '2024-10-01 17:15:54'),
(283, 1, 0, '2024-06-04 00:00:00', 'Out', 'CHA000027', 'INV000027', 57, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 136, 1.00, 200.00, 0.00, 200.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:15:54', '2024-10-01 17:15:54'),
(284, 1, 0, '2024-06-04 00:00:00', 'Out', 'CHA000028', 'INV000028', 65, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 135, 1.00, 550.00, 0.00, 550.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:16:59', '2024-10-01 17:16:59'),
(285, 1, 0, '2024-06-13 00:00:00', 'Out', 'CHA000029', 'INV000029', 3, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 133, 2.00, 9500.00, 0.00, 19000.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:23:55', '2024-10-01 17:23:55'),
(286, 1, 0, '2024-06-08 00:00:00', 'Out', 'CHA000030', 'INV000030', 6, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 143, 1.00, 120.00, 0.00, 120.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:24:59', '2024-10-01 17:24:59'),
(287, 1, 0, '2024-06-08 00:00:00', 'Out', 'CHA000030', 'INV000030', 57, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 143, 1.00, 80.00, 0.00, 80.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:24:59', '2024-10-01 17:24:59'),
(288, 1, 0, '2024-06-08 00:00:00', 'Out', 'CHA000030', 'INV000030', 55, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 143, 1.00, 80.00, 0.00, 80.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:24:59', '2024-10-01 17:24:59'),
(289, 1, 0, '2024-06-08 00:00:00', 'Out', 'CHA000033', 'INV000033', 6, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 144, 2.00, 120.00, 0.00, 240.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:26:39', '2024-10-01 17:26:39'),
(290, 1, 0, '2024-06-08 00:00:00', 'Out', 'CHA000033', 'INV000033', 55, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 144, 1.00, 160.00, 0.00, 160.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:26:39', '2024-10-01 17:26:39'),
(291, 1, 0, '2024-06-09 00:00:00', 'Out', 'CHA000031', 'INV000031', 62, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 142, 1.00, 1850.00, 0.00, 1850.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:28:48', '2024-10-01 17:28:48'),
(292, 1, 0, '2024-06-09 00:00:00', 'Out', 'CHA000031', 'INV000031', 55, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 142, 1.00, 300.00, 0.00, 300.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:28:48', '2024-10-01 17:28:48'),
(293, 1, 0, '2024-06-29 00:00:00', 'Out', 'CHA000032', 'INV000032', 3, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 137, 1.00, 11500.00, 2000.00, 9500.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:30:22', '2024-10-01 17:30:22'),
(294, 1, 0, '2024-06-29 00:00:00', 'Out', 'CHA000032', 'INV000032', 59, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 137, 15.00, 10.00, 0.00, 150.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:30:22', '2024-10-01 17:30:22'),
(295, 1, 0, '2024-06-27 00:00:00', 'Out', 'CHA000034', 'INV000034', 3, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 138, 1.00, 10500.00, 1000.00, 9500.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:32:04', '2024-10-01 17:32:04'),
(296, 1, 0, '2024-06-27 00:00:00', 'Out', 'CHA000034', 'INV000034', 59, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 138, 15.00, 10.00, 0.00, 150.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:32:04', '2024-10-01 17:32:04'),
(297, 1, 0, '2024-06-30 00:00:00', 'Out', 'CHA000035', 'INV000035', 6, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 131, 1.00, 120.00, 0.00, 120.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:33:44', '2024-10-01 17:33:44'),
(298, 1, 0, '2024-06-30 00:00:00', 'Out', 'CHA000059', 'INV000059', 6, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 139, 4.00, 125.00, NULL, 500.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:40:06', '2024-10-01 17:40:06'),
(299, 1, 0, '2024-06-30 00:00:00', 'Out', 'CHA000059', 'INV000059', 8, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 139, 1.00, 240.00, NULL, 240.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:40:06', '2024-10-01 17:40:06'),
(300, 1, 0, '2024-06-30 00:00:00', 'Out', 'CHA000059', 'INV000059', 7, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 139, 1.00, 240.00, NULL, 240.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:40:06', '2024-10-01 17:40:06'),
(301, 1, 0, '2024-06-30 00:00:00', 'Out', 'CHA000059', 'INV000059', 57, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 139, 1.00, 300.00, NULL, 300.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:40:06', '2024-10-01 17:40:06'),
(302, 1, 0, '2024-07-01 00:00:00', 'Out', 'CHA000036', 'INV000036', 3, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 140, 1.00, 11500.00, 2000.00, 9500.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:55:21', '2024-10-01 17:55:21'),
(303, 1, 0, '2024-07-01 00:00:00', 'Out', 'CHA000036', 'INV000036', 59, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 140, 15.00, 10.00, 0.00, 150.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:55:21', '2024-10-01 17:55:21'),
(304, 1, 0, '2024-07-04 00:00:00', 'Out', 'CHA000037', 'INV000037', 6, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 127, 1.00, 120.00, 0.00, 120.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:56:29', '2024-10-01 17:56:29'),
(305, 1, 0, '2024-07-08 00:00:00', 'Out', 'CHA000038', 'INV000038', 6, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 141, 1.00, 120.00, 0.00, 120.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:57:30', '2024-10-01 17:57:30'),
(306, 1, 0, '2024-07-08 00:00:00', 'Out', 'CHA000038', 'INV000038', 7, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 141, 1.00, 250.00, 0.00, 250.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:57:30', '2024-10-01 17:57:30'),
(307, 1, 0, '2024-07-08 00:00:00', 'Out', 'CHA000038', 'INV000038', 8, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 141, 1.00, 250.00, 0.00, 250.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:57:30', '2024-10-01 17:57:30'),
(308, 1, 0, '2024-07-08 00:00:00', 'Out', 'CHA000038', 'INV000038', 55, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 141, 1.00, 300.00, 0.00, 300.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:57:30', '2024-10-01 17:57:30'),
(309, 1, 0, '2024-07-08 00:00:00', 'Out', 'CHA000038', 'INV000038', 57, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 141, 1.00, 300.00, 0.00, 300.00, 'Admin', NULL, 0, NULL, '2024-10-01 17:57:30', '2024-10-01 17:57:30'),
(310, 1, 0, '2024-07-08 00:00:00', 'Out', 'CHA000060', 'INV000060', 27, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 127, 1.00, 700.00, NULL, 700.00, 'Admin', NULL, 0, NULL, '2024-10-01 18:03:25', '2024-10-01 18:03:25'),
(311, 1, 0, '2024-07-11 00:00:00', 'Out', 'CHA000039', 'INV000039', 3, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 134, 1.00, 11500.00, 2000.00, 9500.00, 'Admin', NULL, 0, NULL, '2024-10-01 18:05:15', '2024-10-01 18:05:15'),
(312, 1, 0, '2024-07-13 00:00:00', 'Out', 'CHA000040', 'INV000040', 53, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 145, 3.00, 200.00, 0.00, 600.00, 'Admin', NULL, 0, NULL, '2024-10-01 18:52:28', '2024-10-01 18:52:28'),
(313, 1, 0, '2024-07-13 00:00:00', 'Out', 'CHA000040', 'INV000040', 60, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 145, 1.00, 450.00, 0.00, 450.00, 'Admin', NULL, 0, NULL, '2024-10-01 18:52:28', '2024-10-01 18:52:28'),
(314, 1, 0, '2024-07-13 00:00:00', 'Out', 'CHA000040', 'INV000040', 61, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 145, 1.00, 450.00, 0.00, 450.00, 'Admin', NULL, 0, NULL, '2024-10-01 18:52:28', '2024-10-01 18:52:28'),
(315, 1, 0, '2024-07-13 00:00:00', 'Out', 'CHA000040', 'INV000040', 62, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 145, 1.00, 1750.00, 0.00, 1750.00, 'Admin', NULL, 0, NULL, '2024-10-01 18:52:28', '2024-10-01 18:52:28'),
(316, 1, 0, '2024-07-13 00:00:00', 'Out', 'CHA000040', 'INV000040', 55, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 145, 1.00, 500.00, 0.00, 500.00, 'Admin', NULL, 0, NULL, '2024-10-01 18:52:28', '2024-10-01 18:52:28'),
(444, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 5, 112, '16436', 0.00, 24.00, 150.00, 0.00, 3600.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(445, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 6, 112, '16436', 0.00, 50.00, 33.00, 0.00, 1650.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(446, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 7, 112, '16436', 0.00, 25.00, 90.00, 0.00, 2250.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(447, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 8, 112, '16436', 0.00, 25.00, 90.00, 0.00, 2250.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(448, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 9, 112, '16436', 0.00, 50.00, 8.00, 0.00, 400.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(449, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 10, 112, '16436', 0.00, 50.00, 8.00, 0.00, 400.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(450, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 11, 112, '16436', 0.00, 100.00, 8.00, 0.00, 800.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(451, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 12, 112, '16436', 0.00, 12.00, 230.00, 0.00, 2760.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(452, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 13, 112, '16436', 0.00, 50.00, 15.00, 0.00, 750.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(453, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 14, 112, '16436', 0.00, 24.00, 80.00, 0.00, 1920.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(454, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 15, 112, '16436', 0.00, 12.00, 350.00, 0.00, 4200.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(455, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 16, 112, '16436', 0.00, 25.00, 75.00, 0.00, 1875.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(456, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 17, 112, '16436', 0.00, 25.00, 75.00, 0.00, 1875.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(457, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 18, 112, '16436', 0.00, 20.00, 170.00, 0.00, 3400.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(458, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 19, 112, '16436', 0.00, 24.00, 35.00, 0.00, 840.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(459, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 20, 112, '16436', 0.00, 6.00, 2500.00, 0.00, 15000.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(460, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 21, 112, '16436', 0.00, 12.00, 35.00, 0.00, 420.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(461, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 22, 112, '16436', 0.00, 12.00, 50.00, 0.00, 600.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(462, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 23, 112, '16436', 0.00, 100.00, 15.00, 0.00, 1500.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(463, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 24, 112, '16436', 0.00, 12.00, 600.00, 0.00, 7200.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(464, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 25, 112, '16436', 0.00, 12.00, 750.00, 0.00, 9000.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(465, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 26, 112, '16436', 0.00, 24.00, 90.00, 0.00, 2160.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(466, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 27, 112, '16436', 0.00, 24.00, 150.00, 0.00, 3600.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(467, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 28, 112, '16436', 0.00, 24.00, 170.00, 0.00, 4080.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(468, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 29, 112, '16436', 0.00, 12.00, 1500.00, 0.00, 18000.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(469, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 30, 112, '16436', 0.00, 12.00, 500.00, 0.00, 6000.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(470, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 31, 112, '16436', 0.00, 100.00, 20.00, 0.00, 2000.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(471, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 34, 112, '16436', 0.00, 12.00, 80.00, 0.00, 960.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(472, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 35, 112, '16436', 0.00, 12.00, 150.00, 0.00, 1800.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(473, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 36, 112, '16436', 0.00, 6.00, 120.00, 0.00, 720.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(474, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 37, 112, '16436', 0.00, 1.00, 11000.00, 0.00, 11000.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(475, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 38, 112, '16436', 0.00, 1.00, 6000.00, 0.00, 6000.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(476, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 39, 112, '16436', 0.00, 1.00, 18000.00, 0.00, 18000.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(477, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 40, 112, '16436', 0.00, 1.00, 7000.00, 0.00, 7000.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(478, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 41, 112, '16436', 0.00, 1.00, 12000.00, 0.00, 12000.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(479, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 42, 112, '16436', 0.00, 12.00, 250.00, 0.00, 3000.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(480, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 43, 112, '16436', 0.00, 25.00, 10.00, 0.00, 250.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(481, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 44, 112, '16436', 0.00, 1.00, 1800.00, 0.00, 1800.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(482, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 45, 112, '16436', 0.00, 12.00, 50.00, 0.00, 600.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(483, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 46, 112, '16436', 0.00, 6.00, 2500.00, 0.00, 15000.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(484, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 47, 112, '16436', 0.00, 1.00, 5000.00, 0.00, 5000.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(485, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 48, 112, '16436', 0.00, 10.00, 1400.00, 0.00, 14000.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(486, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 50, 112, '16436', 0.00, 5.00, 1500.00, 0.00, 7500.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(487, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 51, 112, '16436', 0.00, 25.00, 480.00, 0.00, 12000.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(488, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 52, 112, '16436', 0.00, 25.00, 450.00, 0.00, 11250.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(489, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 53, 112, '16436', 0.00, 25.00, 70.00, 0.00, 1750.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(490, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 54, 112, '16436', 0.00, 12.00, 250.00, 0.00, 3000.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(491, 1, 0, '2024-08-22 00:00:00', 'In', NULL, 'PUR000001', 33, 112, '16436', 0.00, 6.00, 80.00, 0.00, 480.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-04 01:47:46', '2024-10-04 01:47:46'),
(496, 1, 0, '2024-09-12 00:00:00', 'Out', 'CHA000056', 'INV000056', 55, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 139, 1.00, 150.00, 0.00, 150.00, 'Admin', NULL, 0, NULL, '2024-10-06 15:09:21', '2024-10-06 15:09:21'),
(497, 1, 0, '2024-09-12 00:00:00', 'Out', 'CHA000056', 'INV000056', 57, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 139, 1.00, 150.00, 0.00, 150.00, 'Admin', NULL, 0, NULL, '2024-10-06 15:09:21', '2024-10-06 15:09:21'),
(498, 1, 0, '2024-08-24 00:00:00', 'Out', 'CHA000054', 'INV000054', 15, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 147, 1.00, 550.00, 0.00, 550.00, 'Admin', NULL, 0, NULL, '2024-10-06 15:11:03', '2024-10-06 15:11:03'),
(499, 1, 0, '2024-08-24 00:00:00', 'Out', 'CHA000054', 'INV000054', 55, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 147, 1.00, 300.00, 50.00, 250.00, 'Admin', NULL, 0, NULL, '2024-10-06 15:11:03', '2024-10-06 15:11:03'),
(500, 1, 0, '2024-09-18 00:00:00', 'Out', 'CHA000057', 'INV000057', 6, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 149, 1.00, 120.00, 0.00, 120.00, 'Admin', NULL, 0, NULL, '2024-10-06 15:28:54', '2024-10-06 15:28:54'),
(501, 1, 0, '2024-09-18 00:00:00', 'Out', 'CHA000057', 'INV000057', 57, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 149, 1.00, 200.00, 0.00, 200.00, 'Admin', NULL, 0, NULL, '2024-10-06 15:28:54', '2024-10-06 15:28:54'),
(502, 1, 0, '2024-08-28 00:00:00', 'Out', 'CHA000053', 'INV000053', 6, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 140, 1.00, 120.00, 0.00, 120.00, 'Admin', NULL, 0, NULL, '2024-10-06 15:30:42', '2024-10-06 15:30:42'),
(503, 1, 0, '2024-08-28 00:00:00', 'Out', 'CHA000053', 'INV000053', 7, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 140, 1.00, 250.00, 0.00, 250.00, 'Admin', NULL, 0, NULL, '2024-10-06 15:30:42', '2024-10-06 15:30:42'),
(504, 1, 0, '2024-08-28 00:00:00', 'Out', 'CHA000053', 'INV000053', 8, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 140, 1.00, 250.00, 0.00, 250.00, 'Admin', NULL, 0, NULL, '2024-10-06 15:30:42', '2024-10-06 15:30:42'),
(505, 1, 0, '2024-08-28 00:00:00', 'Out', 'CHA000053', 'INV000053', 57, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 140, 1.00, 300.00, 0.00, 300.00, 'Admin', NULL, 0, NULL, '2024-10-06 15:30:42', '2024-10-06 15:30:42'),
(506, 1, 0, '2024-08-17 00:00:00', 'Out', 'CHA000051', 'INV000051', 6, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 124, 1.00, 120.00, 0.00, 120.00, 'Admin', NULL, 0, NULL, '2024-10-06 15:32:52', '2024-10-06 15:32:52'),
(507, 1, 0, '2024-08-17 00:00:00', 'Out', 'CHA000051', 'INV000051', 7, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 124, 1.00, 250.00, 0.00, 250.00, 'Admin', NULL, 0, NULL, '2024-10-06 15:32:52', '2024-10-06 15:32:52'),
(508, 1, 0, '2024-08-17 00:00:00', 'Out', 'CHA000051', 'INV000051', 8, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 124, 1.00, 250.00, 0.00, 250.00, 'Admin', NULL, 0, NULL, '2024-10-06 15:32:52', '2024-10-06 15:32:52'),
(509, 1, 0, '2024-08-17 00:00:00', 'Out', 'CHA000051', 'INV000051', 57, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 124, 1.00, 300.00, 0.00, 300.00, 'Admin', NULL, 0, NULL, '2024-10-06 15:32:52', '2024-10-06 15:32:52'),
(515, 1, 0, '2024-04-22 00:00:00', 'Out', 'CHA000006', 'INV000006', 3, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 116, 1.00, 11500.00, 1500.00, 10000.00, 'Admin', NULL, 0, NULL, '2024-10-06 16:10:51', '2024-10-06 16:10:51'),
(516, 1, 0, '2024-04-22 00:00:00', 'Out', 'CHA000006', 'INV000006', 59, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 116, 4.00, 10.00, 0.00, 40.00, 'Admin', NULL, 0, NULL, '2024-10-06 16:10:51', '2024-10-06 16:10:51'),
(517, 1, 0, '2024-05-04 00:00:00', 'Out', 'CHA000011', 'INV000011', 3, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 121, 1.00, 11500.00, 2000.00, 9500.00, 'Admin', NULL, 0, NULL, '2024-10-06 16:17:48', '2024-10-06 16:17:48'),
(518, 1, 0, '2024-08-17 00:00:00', 'Out', 'CHA000052', 'INV000052', 6, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 133, 1.00, 120.00, 0.00, 120.00, 'Admin', NULL, 0, NULL, '2024-10-06 16:45:55', '2024-10-06 16:45:55'),
(519, 1, 0, '2024-04-20 00:00:00', 'Out', 'CHA000061', 'INV000061', 3, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 115, 1.00, 11500.00, 2000.00, 9500.00, 'Admin', NULL, 0, NULL, '2024-10-06 16:59:13', '2024-10-06 16:59:13'),
(520, 1, 0, '2024-04-20 00:00:00', 'Out', 'CHA000061', 'INV000061', 59, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 115, 25.00, 10.00, NULL, 250.00, 'Admin', NULL, 0, NULL, '2024-10-06 16:59:13', '2024-10-06 16:59:13'),
(521, 1, 0, '2024-07-14 00:00:00', 'Out', 'CHA000062', 'INV000062', 3, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 146, 1.00, 11500.00, 2300.00, 9200.00, 'Admin', NULL, 0, NULL, '2024-10-06 17:13:46', '2024-10-06 17:13:46'),
(523, 1, 0, '2024-07-25 00:00:00', 'Out', 'CHA000063', 'INV000063', 6, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 147, 2.00, 120.00, 0.00, 240.00, 'Admin', NULL, 0, NULL, '2024-10-06 17:19:18', '2024-10-06 17:19:18'),
(524, 1, 0, '2024-07-25 00:00:00', 'Out', 'CHA000064', 'INV000064', 27, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 125, 1.00, 500.00, NULL, 500.00, 'Admin', NULL, 0, NULL, '2024-10-06 17:25:36', '2024-10-06 17:25:36'),
(525, 1, 0, '2024-07-25 00:00:00', 'Out', 'CHA000064', 'INV000064', 6, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 125, 1.00, 120.00, NULL, 120.00, 'Admin', NULL, 0, NULL, '2024-10-06 17:25:36', '2024-10-06 17:25:36'),
(526, 1, 0, '2024-07-25 00:00:00', 'Out', 'CHA000064', 'INV000064', 11, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 125, 2.00, 25.00, NULL, 50.00, 'Admin', NULL, 0, NULL, '2024-10-06 17:25:36', '2024-10-06 17:25:36'),
(527, 1, 0, '2024-07-25 00:00:00', 'Out', 'CHA000064', 'INV000064', 57, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 125, 1.00, 200.00, 170.00, 30.00, 'Admin', NULL, 0, NULL, '2024-10-06 17:25:36', '2024-10-06 17:25:36'),
(528, 1, 0, '2024-07-30 00:00:00', 'Out', 'CHA000065', 'INV000065', 6, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 129, 1.00, 120.00, NULL, 120.00, 'Admin', NULL, 0, NULL, '2024-10-06 17:30:58', '2024-10-06 17:30:58'),
(529, 1, 0, '2024-07-30 00:00:00', 'Out', 'CHA000065', 'INV000065', 7, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 129, 1.00, 250.00, NULL, 250.00, 'Admin', NULL, 0, NULL, '2024-10-06 17:30:58', '2024-10-06 17:30:58'),
(530, 1, 0, '2024-07-30 00:00:00', 'Out', 'CHA000065', 'INV000065', 8, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 129, 1.00, 250.00, NULL, 250.00, 'Admin', NULL, 0, NULL, '2024-10-06 17:30:58', '2024-10-06 17:30:58'),
(531, 1, 0, '2024-07-30 00:00:00', 'Out', 'CHA000065', 'INV000065', 55, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 129, 1.00, 300.00, NULL, 300.00, 'Admin', NULL, 0, NULL, '2024-10-06 17:30:58', '2024-10-06 17:30:58'),
(532, 1, 0, '2024-07-30 00:00:00', 'Out', 'CHA000066', 'INV000066', 7, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 118, 1.00, 250.00, NULL, 250.00, 'Admin', NULL, 0, NULL, '2024-10-06 17:35:09', '2024-10-06 17:35:09'),
(533, 1, 0, '2024-07-30 00:00:00', 'Out', 'CHA000066', 'INV000066', 8, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 118, 1.00, 250.00, NULL, 250.00, 'Admin', NULL, 0, NULL, '2024-10-06 17:35:09', '2024-10-06 17:35:09'),
(534, 1, 0, '2024-07-30 00:00:00', 'Out', 'CHA000066', 'INV000066', 57, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 118, 1.00, 100.00, NULL, 100.00, 'Admin', NULL, 0, NULL, '2024-10-06 17:35:09', '2024-10-06 17:35:09'),
(535, 1, 0, '2024-07-30 00:00:00', 'Out', 'CHA000066', 'INV000066', 6, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 118, 1.00, 100.00, NULL, 100.00, 'Admin', NULL, 0, NULL, '2024-10-06 17:35:09', '2024-10-06 17:35:09'),
(536, 1, 0, '2024-08-01 00:00:00', 'Out', 'CHA000067', 'INV000067', 3, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 149, 1.00, 9200.00, NULL, 9200.00, 'Admin', NULL, 0, NULL, '2024-10-06 17:37:46', '2024-10-06 17:37:46'),
(537, NULL, 0, '2024-08-01 00:00:00', 'Out', 'CHA000068', 'INV000068', 6, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 133, 5.00, 120.00, NULL, 600.00, 'Admin', NULL, 0, NULL, '2024-10-06 17:40:29', '2024-10-06 17:40:29'),
(538, NULL, 0, '2024-08-01 00:00:00', 'Out', 'CHA000068', 'INV000068', 7, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 133, 1.00, 250.00, NULL, 250.00, 'Admin', NULL, 0, NULL, '2024-10-06 17:40:29', '2024-10-06 17:40:29'),
(539, NULL, 0, '2024-08-01 00:00:00', 'Out', 'CHA000068', 'INV000068', 8, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 133, 1.00, 250.00, NULL, 250.00, 'Admin', NULL, 0, NULL, '2024-10-06 17:40:29', '2024-10-06 17:40:29'),
(540, NULL, 0, '2024-08-01 00:00:00', 'Out', 'CHA000068', 'INV000068', 57, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 133, 1.00, 300.00, NULL, 300.00, 'Admin', NULL, 0, NULL, '2024-10-06 17:40:29', '2024-10-06 17:40:29'),
(541, 1, 0, '2024-08-12 00:00:00', 'Out', 'CHA000069', 'INV000069', 6, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 128, 1.00, 120.00, NULL, 120.00, 'Admin', NULL, 0, NULL, '2024-10-06 17:43:31', '2024-10-06 17:43:31'),
(542, 1, 0, '2024-08-12 00:00:00', 'Out', 'CHA000069', 'INV000069', 7, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 128, 1.00, 250.00, NULL, 250.00, 'Admin', NULL, 0, NULL, '2024-10-06 17:43:31', '2024-10-06 17:43:31'),
(543, 1, 0, '2024-08-12 00:00:00', 'Out', 'CHA000069', 'INV000069', 8, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 128, 1.00, 250.00, NULL, 250.00, 'Admin', NULL, 0, NULL, '2024-10-06 17:43:31', '2024-10-06 17:43:31'),
(544, 1, 0, '2024-08-12 00:00:00', 'Out', 'CHA000069', 'INV000069', 57, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 128, 1.00, 300.00, NULL, 300.00, 'Admin', NULL, 0, NULL, '2024-10-06 17:43:31', '2024-10-06 17:43:31'),
(545, 1, 0, '2024-08-13 00:00:00', 'Out', 'CHA000070', 'INV000070', 6, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 130, 1.00, 120.00, NULL, 120.00, 'Admin', NULL, 0, NULL, '2024-10-06 17:47:22', '2024-10-06 17:47:22'),
(546, 1, 0, '2024-08-13 00:00:00', 'Out', 'CHA000070', 'INV000070', 7, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 130, 1.00, 250.00, NULL, 250.00, 'Admin', NULL, 0, NULL, '2024-10-06 17:47:22', '2024-10-06 17:47:22'),
(547, 1, 0, '2024-08-13 00:00:00', 'Out', 'CHA000070', 'INV000070', 8, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 130, 1.00, 250.00, NULL, 250.00, 'Admin', NULL, 0, NULL, '2024-10-06 17:47:22', '2024-10-06 17:47:22'),
(548, 1, 0, '2024-08-13 00:00:00', 'Out', 'CHA000070', 'INV000070', 27, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 130, 1.00, 450.00, 70.00, 380.00, 'Admin', NULL, 0, NULL, '2024-10-06 17:47:22', '2024-10-06 17:47:22'),
(561, 1, 0, '2024-08-14 00:00:00', 'Out', 'CHA000071', 'INV000071', 6, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 122, 1.00, 120.00, 0.00, 120.00, 'Admin', NULL, 0, NULL, '2024-10-06 23:19:05', '2024-10-06 23:19:05'),
(562, 1, 0, '2024-08-14 00:00:00', 'Out', 'CHA000071', 'INV000071', 7, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 122, 1.00, 250.00, 0.00, 250.00, 'Admin', NULL, 0, NULL, '2024-10-06 23:19:05', '2024-10-06 23:19:05'),
(563, 1, 0, '2024-08-14 00:00:00', 'Out', 'CHA000071', 'INV000071', 8, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 122, 1.00, 250.00, 0.00, 250.00, 'Admin', NULL, 0, NULL, '2024-10-06 23:19:05', '2024-10-06 23:19:05'),
(564, 1, 0, '2024-08-14 00:00:00', 'Out', 'CHA000071', 'INV000071', 57, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 122, 1.00, 300.00, 20.00, 280.00, 'Admin', NULL, 0, NULL, '2024-10-06 23:19:05', '2024-10-06 23:19:05'),
(565, 1, 0, '2024-09-19 00:00:00', 'Out', 'CHA000072', 'INV000072', 6, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 125, 1.00, 120.00, NULL, 120.00, 'Admin', NULL, 0, NULL, '2024-10-06 23:27:42', '2024-10-06 23:27:42'),
(566, 1, 0, '2024-09-19 00:00:00', 'Out', 'CHA000072', 'INV000072', 57, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 125, 1.00, 180.00, NULL, 180.00, 'Admin', NULL, 0, NULL, '2024-10-06 23:27:42', '2024-10-06 23:27:42'),
(567, 1, 0, '2024-09-30 00:00:00', 'Out', 'CHA000073', 'INV000073', 3, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 150, 1.00, 10500.00, 500.00, 10000.00, 'Admin', NULL, 0, NULL, '2024-10-06 23:33:51', '2024-10-06 23:33:51'),
(568, 1, 0, '2024-10-03 00:00:00', 'Out', 'CHA000074', 'INV000074', 3, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 151, 1.00, 9000.00, NULL, 9000.00, 'Admin', NULL, 0, NULL, '2024-10-07 00:11:10', '2024-10-07 00:11:10'),
(569, 1, 0, '2024-10-05 00:00:00', 'Out', 'CHA000075', 'INV000075', 6, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 152, 1.00, 120.00, NULL, 120.00, 'Admin', NULL, 0, NULL, '2024-10-07 00:13:03', '2024-10-07 00:13:03'),
(570, 1, 0, '2024-10-05 00:00:00', 'Out', 'CHA000075', 'INV000075', 57, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 152, 1.00, 300.00, NULL, 300.00, 'Admin', NULL, 0, NULL, '2024-10-07 00:13:03', '2024-10-07 00:13:03'),
(572, 1, 0, '2024-01-30 00:00:00', 'In', NULL, 'PUR000002', 3, 112, NULL, 0.00, 100.00, 7100.00, 0.00, 710000.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-17 17:05:34', '2024-10-17 17:05:34'),
(573, 1, 0, '2024-01-30 00:00:00', 'In', NULL, 'PUR000002', 4, 112, NULL, 0.00, 100.00, 2347.00, 0.00, 234700.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-17 17:05:34', '2024-10-17 17:05:34'),
(574, NULL, 0, '2024-01-30 00:00:00', 'In', NULL, 'PUR000021', 59, 112, NULL, 0.00, 1000.00, 4.50, 0.00, 4500.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-10-17 23:46:29', '2024-10-17 23:46:29'),
(575, 1, 0, '2024-10-02 00:00:00', 'Out', 'CHA000076', 'INV000076', 3, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 153, 1.00, 10500.00, 1300.00, 9200.00, 'Admin', NULL, 0, NULL, '2024-10-19 22:19:23', '2024-10-19 22:19:23'),
(576, 1, 0, '2024-10-09 00:00:00', 'Out', 'CHA000077', 'INV000077', 37, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 154, 1.00, 12000.00, 0.00, 12000.00, 'Admin', NULL, 0, NULL, '2024-10-19 22:46:28', '2024-10-19 22:46:28'),
(578, 1, 0, '2024-10-07 00:00:00', 'Out', 'CHA000079', 'INV000079', 6, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 138, 1.00, 120.00, 0.00, 120.00, 'Admin', NULL, 0, NULL, '2024-10-19 23:19:22', '2024-10-19 23:19:22'),
(579, 1, 0, '2024-10-07 00:00:00', 'Out', 'CHA000079', 'INV000079', 7, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 138, 1.00, 250.00, 0.00, 250.00, 'Admin', NULL, 0, NULL, '2024-10-19 23:19:22', '2024-10-19 23:19:22'),
(580, 1, 0, '2024-10-07 00:00:00', 'Out', 'CHA000079', 'INV000079', 8, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 138, 1.00, 250.00, 0.00, 250.00, 'Admin', NULL, 0, NULL, '2024-10-19 23:19:22', '2024-10-19 23:19:22'),
(581, 1, 0, '2024-10-07 00:00:00', 'Out', 'CHA000079', 'INV000079', 57, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 138, 1.00, 300.00, 220.00, 80.00, 'Admin', NULL, 0, NULL, '2024-10-19 23:19:22', '2024-10-19 23:19:22'),
(602, 1, 0, '2024-07-27 00:00:00', 'Out', 'CHA000083', 'INV000083', 6, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 142, 1.00, 120.00, 0.00, 120.00, 'Admin', NULL, 0, NULL, '2024-10-30 16:12:32', '2024-10-30 16:12:32'),
(603, 1, 0, '2024-07-27 00:00:00', 'Out', 'CHA000083', 'INV000083', 55, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 142, 1.00, 78.00, 0.00, 78.00, 'Admin', NULL, 0, NULL, '2024-10-30 16:12:32', '2024-10-30 16:12:32'),
(604, 1, 0, '2024-09-12 00:00:00', 'Out', 'CHA000055', 'INV000055', 6, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 142, 1.00, 120.00, 0.00, 120.00, 'Admin', NULL, 0, NULL, '2024-10-30 16:14:36', '2024-10-30 16:14:36'),
(605, 1, 0, '2024-09-12 00:00:00', 'Out', 'CHA000055', 'INV000055', 7, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 142, 1.00, 250.00, 0.00, 250.00, 'Admin', NULL, 0, NULL, '2024-10-30 16:14:36', '2024-10-30 16:14:36'),
(606, 1, 0, '2024-09-12 00:00:00', 'Out', 'CHA000055', 'INV000055', 8, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 142, 1.00, 250.00, 0.00, 250.00, 'Admin', NULL, 0, NULL, '2024-10-30 16:14:36', '2024-10-30 16:14:36'),
(607, 1, 0, '2024-09-12 00:00:00', 'Out', 'CHA000055', 'INV000055', 55, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 142, 1.00, 78.00, NULL, 78.00, 'Admin', NULL, 0, NULL, '2024-10-30 16:14:36', '2024-10-30 16:14:36'),
(608, 1, 0, '2024-10-07 00:00:00', 'Out', 'CHA000080', 'INV000080', 6, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 142, 1.00, 120.00, 0.00, 120.00, 'Admin', NULL, 0, NULL, '2024-10-30 16:17:12', '2024-10-30 16:17:12'),
(609, 1, 0, '2024-10-07 00:00:00', 'Out', 'CHA000080', 'INV000080', 55, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 142, 1.00, 78.00, NULL, 78.00, 'Admin', NULL, 0, NULL, '2024-10-30 16:17:12', '2024-10-30 16:17:12'),
(610, 1, 0, '2024-10-16 00:00:00', 'Out', 'CHA000081', 'INV000081', 52, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 142, 1.00, 950.00, 0.00, 950.00, 'Admin', NULL, 0, NULL, '2024-10-30 16:19:00', '2024-10-30 16:19:00'),
(611, 1, 0, '2024-10-16 00:00:00', 'Out', 'CHA000081', 'INV000081', 55, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 142, 1.00, 78.00, NULL, 78.00, 'Admin', NULL, 0, NULL, '2024-10-30 16:19:00', '2024-10-30 16:19:00'),
(612, 1, 0, '2024-10-19 00:00:00', 'Out', 'CHA000082', 'INV000082', 6, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 142, 1.00, 100.00, 0.00, 100.00, 'Admin', NULL, 0, NULL, '2024-10-30 16:21:03', '2024-10-30 16:21:03'),
(613, 1, 0, '2024-10-19 00:00:00', 'Out', 'CHA000082', 'INV000082', 7, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 142, 1.00, 200.00, 0.00, 200.00, 'Admin', NULL, 0, NULL, '2024-10-30 16:21:03', '2024-10-30 16:21:03'),
(614, 1, 0, '2024-10-19 00:00:00', 'Out', 'CHA000082', 'INV000082', 8, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 142, 1.00, 200.00, 0.00, 200.00, 'Admin', NULL, 0, NULL, '2024-10-30 16:21:03', '2024-10-30 16:21:03'),
(615, 1, 0, '2024-10-19 00:00:00', 'Out', 'CHA000082', 'INV000082', 55, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 142, 1.00, 78.00, NULL, 78.00, 'Admin', NULL, 0, NULL, '2024-10-30 16:21:03', '2024-10-30 16:21:03'),
(616, 1, 0, '2024-10-21 00:00:00', 'Out', 'CHA000084', 'INV000084', 6, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 158, 1.00, 100.00, 0.00, 100.00, 'Admin', NULL, 0, NULL, '2024-10-30 17:53:24', '2024-10-30 17:53:24'),
(617, 1, 0, '2024-10-21 00:00:00', 'Out', 'CHA000084', 'INV000084', 7, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 158, 1.00, 350.00, 0.00, 350.00, 'Admin', NULL, 0, NULL, '2024-10-30 17:53:24', '2024-10-30 17:53:24'),
(618, 1, 0, '2024-10-21 00:00:00', 'Out', 'CHA000084', 'INV000084', 8, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 158, 1.00, 350.00, 0.00, 350.00, 'Admin', NULL, 0, NULL, '2024-10-30 17:53:24', '2024-10-30 17:53:24'),
(619, 1, 0, '2024-10-21 00:00:00', 'Out', 'CHA000084', 'INV000084', 55, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 158, 1.00, 500.00, 0.00, 500.00, 'Admin', NULL, 0, NULL, '2024-10-30 17:53:24', '2024-10-30 17:53:24'),
(620, 1, 0, '2024-09-23 00:00:00', 'Out', 'CHA000085', 'INV000085', 6, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 127, 1.00, 100.00, 0.00, 100.00, 'Admin', NULL, 0, NULL, '2024-10-30 18:30:44', '2024-10-30 18:30:44'),
(621, 1, 0, '2024-09-23 00:00:00', 'Out', 'CHA000085', 'INV000085', 7, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 127, 1.00, 250.00, 0.00, 250.00, 'Admin', NULL, 0, NULL, '2024-10-30 18:30:44', '2024-10-30 18:30:44'),
(622, 1, 0, '2024-09-23 00:00:00', 'Out', 'CHA000085', 'INV000085', 8, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 127, 1.00, 250.00, 0.00, 250.00, 'Admin', NULL, 0, NULL, '2024-10-30 18:30:44', '2024-10-30 18:30:44'),
(623, 1, 0, '2024-09-23 00:00:00', 'Out', 'CHA000085', 'INV000085', 57, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 127, 1.00, 100.00, 0.00, 100.00, 'Admin', NULL, 0, NULL, '2024-10-30 18:30:44', '2024-10-30 18:30:44'),
(624, 1, 0, '2024-10-10 00:00:00', 'Out', 'CHA000086', 'INV000086', 3, NULL, NULL, 7100.00, 0.00, 0.00, 0.00, 0.00, 128, 1.00, 9500.00, 0.00, 9500.00, 'Admin', NULL, 0, NULL, '2024-11-19 22:10:07', '2024-11-19 22:10:07'),
(625, 1, 0, '2024-10-23 00:00:00', 'Out', 'CHA000087', 'INV000087', 6, NULL, NULL, 33.00, 0.00, 0.00, 0.00, 0.00, 159, 1.00, 120.00, 0.00, 120.00, 'Admin', NULL, 0, NULL, '2024-11-19 22:17:11', '2024-11-19 22:17:11'),
(626, 1, 0, '2024-10-23 00:00:00', 'Out', 'CHA000087', 'INV000087', 7, NULL, NULL, 90.00, 0.00, 0.00, 0.00, 0.00, 159, 1.00, 250.00, 0.00, 250.00, 'Admin', NULL, 0, NULL, '2024-11-19 22:17:11', '2024-11-19 22:17:11'),
(627, 1, 0, '2024-10-23 00:00:00', 'Out', 'CHA000087', 'INV000087', 8, NULL, NULL, 90.00, 0.00, 0.00, 0.00, 0.00, 159, 1.00, 250.00, 0.00, 250.00, 'Admin', NULL, 0, NULL, '2024-11-19 22:17:11', '2024-11-19 22:17:11'),
(628, 1, 0, '2024-10-23 00:00:00', 'Out', 'CHA000087', 'INV000087', 57, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 159, 1.00, 300.00, 0.00, 300.00, 'Admin', NULL, 0, NULL, '2024-11-19 22:17:11', '2024-11-19 22:17:11'),
(631, 1, 0, '2024-10-28 00:00:00', 'Out', 'CHA000089', 'INV000089', 3, NULL, NULL, 7100.00, 0.00, 0.00, 0.00, 0.00, 161, 1.00, 14800.00, 0.00, 14800.00, 'Admin', NULL, 0, NULL, '2024-11-19 22:30:51', '2024-11-19 22:30:51'),
(632, 1, 0, '2024-11-01 00:00:00', 'Out', 'CHA000090', 'INV000090', 7, NULL, NULL, 90.00, 0.00, 0.00, 0.00, 0.00, 135, 1.00, 250.00, 0.00, 250.00, 'Admin', NULL, 0, NULL, '2024-11-19 22:32:44', '2024-11-19 22:32:44'),
(633, 1, 0, '2024-11-01 00:00:00', 'Out', 'CHA000090', 'INV000090', 8, NULL, NULL, 90.00, 0.00, 0.00, 0.00, 0.00, 135, 1.00, 250.00, 0.00, 250.00, 'Admin', NULL, 0, NULL, '2024-11-19 22:32:44', '2024-11-19 22:32:44'),
(634, 1, 0, '2024-11-01 00:00:00', 'Out', 'CHA000090', 'INV000090', 20, NULL, NULL, 2500.00, 0.00, 0.00, 0.00, 0.00, 135, 1.00, 3700.00, 0.00, 3700.00, 'Admin', NULL, 0, NULL, '2024-11-19 22:32:44', '2024-11-19 22:32:44'),
(635, 1, 0, '2024-11-01 00:00:00', 'Out', 'CHA000090', 'INV000090', 57, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 135, 1.00, 200.00, 0.00, 200.00, 'Admin', NULL, 0, NULL, '2024-11-19 22:32:44', '2024-11-19 22:32:44');
INSERT INTO `stocks` (`id`, `warehouse_id`, `to_warehouse_id`, `stock_date`, `stock_type`, `delivery_challan_no`, `invoice_no`, `product_id`, `supplier_id`, `supplier_invoice_no`, `purchase_price`, `stock_in_quantity`, `stock_in_unit_price`, `stock_in_discount`, `stock_in_total_amount`, `customer_id`, `stock_out_quantity`, `stock_out_unit_price`, `stock_out_discount`, `stock_out_total_amount`, `done_by`, `remarks`, `status`, `product_service_detail_id`, `created_at`, `updated_at`) VALUES
(636, 1, 0, '2024-11-03 00:00:00', 'Out', 'CHA000091', 'INV000091', 55, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 162, 1.00, 500.00, 0.00, 500.00, 'Admin', NULL, 0, NULL, '2024-11-19 22:36:11', '2024-11-19 22:36:11'),
(637, 1, 0, '2024-11-03 00:00:00', 'Out', 'CHA000092', 'INV000092', 55, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 163, 1.00, 400.00, 0.00, 400.00, 'Admin', NULL, 0, NULL, '2024-11-19 22:51:05', '2024-11-19 22:51:05'),
(638, 1, 0, '2024-11-04 00:00:00', 'Out', 'CHA000093', 'INV000093', 55, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 164, 1.00, 500.00, 0.00, 500.00, 'Admin', NULL, 0, NULL, '2024-11-19 22:53:35', '2024-11-19 22:53:35'),
(639, 1, 0, '2024-11-10 00:00:00', 'Out', 'CHA000094', 'INV000094', 3, NULL, NULL, 7100.00, 0.00, 0.00, 0.00, 0.00, 165, 1.00, 10000.00, 0.00, 10000.00, 'Admin', NULL, 0, NULL, '2024-11-19 23:01:12', '2024-11-19 23:01:12'),
(640, 1, 0, '2024-11-10 00:00:00', 'Out', 'CHA000094', 'INV000094', 28, NULL, NULL, 170.00, 0.00, 0.00, 0.00, 0.00, 165, 1.00, 400.00, 0.00, 400.00, 'Admin', NULL, 0, NULL, '2024-11-19 23:01:12', '2024-11-19 23:01:12'),
(641, 1, 0, '2024-11-14 00:00:00', 'Out', 'CHA000095', 'INV000095', 55, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 165, 1.00, 300.00, 0.00, 300.00, 'Admin', NULL, 0, NULL, '2024-11-19 23:02:58', '2024-11-19 23:02:58'),
(642, 1, 0, '2024-11-14 00:00:00', 'Out', 'CHA000095', 'INV000095', 59, NULL, NULL, 4.50, 0.00, 0.00, 0.00, 0.00, 165, 5.00, 20.00, 0.00, 100.00, 'Admin', NULL, 0, NULL, '2024-11-19 23:02:58', '2024-11-19 23:02:58'),
(643, 1, 0, '2024-11-18 00:00:00', 'Out', 'CHA000096', 'INV000096', 55, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 166, 1.00, 300.00, 0.00, 300.00, 'Admin', NULL, 0, NULL, '2024-11-19 23:06:25', '2024-11-19 23:06:25'),
(644, 1, 0, '2024-11-18 00:00:00', 'Out', 'CHA000097', 'INV000097', 6, NULL, NULL, 33.00, 0.00, 0.00, 0.00, 0.00, 143, 1.00, 100.00, 0.00, 100.00, 'Admin', NULL, 0, NULL, '2024-11-19 23:12:42', '2024-11-19 23:12:42'),
(645, 1, 0, '2024-11-18 00:00:00', 'Out', 'CHA000097', 'INV000097', 7, NULL, NULL, 90.00, 0.00, 0.00, 0.00, 0.00, 143, 1.00, 250.00, 0.00, 250.00, 'Admin', NULL, 0, NULL, '2024-11-19 23:12:42', '2024-11-19 23:12:42'),
(646, 1, 0, '2024-11-18 00:00:00', 'Out', 'CHA000097', 'INV000097', 8, NULL, NULL, 90.00, 0.00, 0.00, 0.00, 0.00, 143, 1.00, 250.00, 0.00, 250.00, 'Admin', NULL, 0, NULL, '2024-11-19 23:12:42', '2024-11-19 23:12:42'),
(647, 1, 0, '2024-11-18 00:00:00', 'Out', 'CHA000097', 'INV000097', 55, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 143, 1.00, 100.00, 0.00, 100.00, 'Admin', NULL, 0, NULL, '2024-11-19 23:12:42', '2024-11-19 23:12:42'),
(648, NULL, 0, '2024-11-20 00:00:00', 'Out', 'CHA000098', 'INV000098', 3, NULL, NULL, 7100.00, 0.00, 0.00, 0.00, 0.00, 108, 1.00, 10000.00, 0.00, 10000.00, 'Admin', 'remarks..', 0, 26, '2024-11-20 20:49:52', '2024-11-20 20:49:52'),
(649, NULL, 0, '2024-11-20 00:00:00', 'Out', 'CHA000098', 'INV000098', 67, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 108, 1.00, 500.00, 0.00, 500.00, 'Admin', 'remarks..', 0, 26, '2024-11-20 20:49:52', '2024-11-20 20:49:52'),
(650, NULL, 0, '2024-11-20 00:00:00', 'Out', 'CHA000098', 'INV000098', 66, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 108, 1.00, 300.00, 0.00, 300.00, 'Admin', 'CNG', 0, 26, '2024-11-20 20:49:52', '2024-11-20 20:49:52'),
(651, 1, 0, '2024-11-19 00:00:00', 'Out', 'CHA000099', 'INV000099', 6, NULL, NULL, 33.00, 0.00, 0.00, 0.00, 0.00, 129, 1.00, 100.00, 0.00, 100.00, 'Admin', NULL, 0, NULL, '2024-11-23 22:28:17', '2024-11-23 22:28:17'),
(652, 1, 0, '2024-11-19 00:00:00', 'Out', 'CHA000099', 'INV000099', 7, NULL, NULL, 90.00, 0.00, 0.00, 0.00, 0.00, 129, 1.00, 250.00, 0.00, 250.00, 'Admin', NULL, 0, NULL, '2024-11-23 22:28:17', '2024-11-23 22:28:17'),
(653, 1, 0, '2024-11-19 00:00:00', 'Out', 'CHA000099', 'INV000099', 8, NULL, NULL, 90.00, 0.00, 0.00, 0.00, 0.00, 129, 1.00, 250.00, 0.00, 250.00, 'Admin', NULL, 0, NULL, '2024-11-23 22:28:17', '2024-11-23 22:28:17'),
(654, 1, 0, '2024-11-19 00:00:00', 'Out', 'CHA000099', 'INV000099', 55, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 129, 1.00, 300.00, 0.00, 300.00, 'Admin', NULL, 0, NULL, '2024-11-23 22:28:17', '2024-11-23 22:28:17'),
(655, 1, 0, '2024-11-20 00:00:00', 'Out', 'CHA000100', 'INV000100', 6, NULL, NULL, 33.00, 0.00, 0.00, 0.00, 0.00, 167, 1.00, 100.00, 0.00, 100.00, 'Admin', NULL, 0, NULL, '2024-11-23 22:32:31', '2024-11-23 22:32:31'),
(656, 1, 0, '2024-11-20 00:00:00', 'Out', 'CHA000100', 'INV000100', 7, NULL, NULL, 90.00, 0.00, 0.00, 0.00, 0.00, 167, 1.00, 250.00, 0.00, 250.00, 'Admin', NULL, 0, NULL, '2024-11-23 22:32:31', '2024-11-23 22:32:31'),
(657, 1, 0, '2024-11-20 00:00:00', 'Out', 'CHA000100', 'INV000100', 8, NULL, NULL, 90.00, 0.00, 0.00, 0.00, 0.00, 167, 1.00, 250.00, 0.00, 250.00, 'Admin', NULL, 0, NULL, '2024-11-23 22:32:31', '2024-11-23 22:32:31'),
(658, 1, 0, '2024-11-20 00:00:00', 'Out', 'CHA000100', 'INV000100', 57, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 167, 1.00, 100.00, 0.00, 100.00, 'Admin', NULL, 0, NULL, '2024-11-23 22:32:31', '2024-11-23 22:32:31'),
(659, 1, 0, '2024-11-23 00:00:00', 'Out', 'CHA000101', 'INV000101', 6, NULL, NULL, 33.00, 0.00, 0.00, 0.00, 0.00, 137, 1.00, 100.00, 0.00, 100.00, 'Admin', NULL, 0, NULL, '2024-11-23 22:34:10', '2024-11-23 22:34:10'),
(660, 1, 0, '2024-11-23 00:00:00', 'Out', 'CHA000101', 'INV000101', 7, NULL, NULL, 90.00, 0.00, 0.00, 0.00, 0.00, 137, 1.00, 250.00, 0.00, 250.00, 'Admin', NULL, 0, NULL, '2024-11-23 22:34:10', '2024-11-23 22:34:10'),
(661, 1, 0, '2024-11-23 00:00:00', 'Out', 'CHA000101', 'INV000101', 8, NULL, NULL, 90.00, 0.00, 0.00, 0.00, 0.00, 137, 1.00, 250.00, 0.00, 250.00, 'Admin', NULL, 0, NULL, '2024-11-23 22:34:10', '2024-11-23 22:34:10'),
(662, 1, 0, '2024-11-23 00:00:00', 'Out', 'CHA000101', 'INV000101', 57, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 137, 1.00, 200.00, 0.00, 200.00, 'Admin', NULL, 0, NULL, '2024-11-23 22:34:10', '2024-11-23 22:34:10'),
(663, 1, 0, '2024-10-27 00:00:00', 'Out', 'CHA000088', 'INV000088', 6, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 160, 4.00, 100.00, 0.00, 400.00, 'Admin', NULL, 0, NULL, '2024-11-26 20:07:42', '2024-11-26 20:07:42'),
(664, 1, 0, '2024-10-27 00:00:00', 'Out', 'CHA000088', 'INV000088', 55, NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, 160, 1.00, 400.00, 0.00, 400.00, 'Admin', NULL, 0, NULL, '2024-11-26 20:07:42', '2024-11-26 20:07:42'),
(665, 1, 0, '2024-11-23 00:00:00', 'Out', 'CHA000102', 'INV000102', 6, NULL, NULL, 33.00, 0.00, 0.00, 0.00, 0.00, 168, 1.00, 100.00, 0.00, 100.00, 'Admin', NULL, 0, NULL, '2024-11-26 22:23:41', '2024-11-26 22:23:41'),
(666, 1, 0, '2024-11-23 00:00:00', 'Out', 'CHA000102', 'INV000102', 7, NULL, NULL, 90.00, 0.00, 0.00, 0.00, 0.00, 168, 1.00, 250.00, 0.00, 250.00, 'Admin', NULL, 0, NULL, '2024-11-26 22:23:41', '2024-11-26 22:23:41'),
(667, 1, 0, '2024-11-23 00:00:00', 'Out', 'CHA000102', 'INV000102', 8, NULL, NULL, 90.00, 0.00, 0.00, 0.00, 0.00, 168, 1.00, 250.00, 0.00, 250.00, 'Admin', NULL, 0, NULL, '2024-11-26 22:23:41', '2024-11-26 22:23:41'),
(668, 1, 0, '2024-11-23 00:00:00', 'Out', 'CHA000102', 'INV000102', 13, NULL, NULL, 15.00, 0.00, 0.00, 0.00, 0.00, 168, 1.00, 100.00, 0.00, 100.00, 'Admin', NULL, 0, NULL, '2024-11-26 22:23:41', '2024-11-26 22:23:41'),
(669, 1, 0, '2024-11-25 00:00:00', 'In', NULL, 'PUR000022', 68, 112, NULL, 0.00, 10.00, 8654.00, 0.00, 86540.00, NULL, 0.00, 0.00, 0.00, 0.00, 'Admin', NULL, 0, NULL, '2024-11-27 22:05:59', '2024-11-27 22:05:59');

-- --------------------------------------------------------

--
-- Table structure for table `suppliers`
--

CREATE TABLE `suppliers` (
  `id` int(10) UNSIGNED NOT NULL,
  `ac_id` int(10) DEFAULT NULL,
  `supplier_code` varchar(255) DEFAULT NULL,
  `supplier_name` varchar(255) NOT NULL,
  `supplier_proprietor_name` varchar(255) DEFAULT NULL,
  `supplier_mobile` varchar(255) DEFAULT NULL,
  `supplier_email` varchar(255) DEFAULT NULL,
  `supplier_address` varchar(255) DEFAULT NULL,
  `representative_name` varchar(255) DEFAULT NULL,
  `representative_mobile` varchar(255) DEFAULT NULL,
  `start_date` date DEFAULT NULL,
  `profile_img` varchar(255) DEFAULT NULL,
  `status` int(11) DEFAULT 0,
  `done_by` varchar(100) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `suppliers`
--

INSERT INTO `suppliers` (`id`, `ac_id`, `supplier_code`, `supplier_name`, `supplier_proprietor_name`, `supplier_mobile`, `supplier_email`, `supplier_address`, `representative_name`, `representative_mobile`, `start_date`, `profile_img`, `status`, `done_by`, `created_at`, `updated_at`) VALUES
(1, 107, '001', 'Supplier 1', NULL, '01681952638', NULL, 'Dhaka, Bangladesh', NULL, NULL, '2024-09-01', NULL, 1, ' ', '2024-09-11 12:47:09', '2024-09-24 16:03:56'),
(2, 109, '002', 'Supplier 2', NULL, '01681952638', NULL, 'Gulshan, Dhaka, Bangladesh', NULL, NULL, '2024-09-01', NULL, 1, ' ', '2024-09-12 05:28:28', '2024-11-12 18:49:57'),
(3, 112, '003', 'ABM engineering', NULL, '01841350351', NULL, 'mirpur', NULL, NULL, NULL, NULL, 1, ' ', '2024-09-17 22:13:39', '2024-09-24 16:04:29');

-- --------------------------------------------------------

--
-- Table structure for table `supplier_ledgers`
--

CREATE TABLE `supplier_ledgers` (
  `id` int(10) UNSIGNED NOT NULL,
  `ledger_date` date NOT NULL,
  `supplier_id` int(10) UNSIGNED DEFAULT NULL,
  `supplier_invoice_no` varchar(50) DEFAULT NULL,
  `invoice_no` varchar(50) DEFAULT NULL,
  `debit` decimal(18,2) NOT NULL DEFAULT 0.00,
  `credit` decimal(18,2) NOT NULL DEFAULT 0.00,
  `payment_type` varchar(50) DEFAULT NULL,
  `bank_name` varchar(50) DEFAULT NULL,
  `cheque_no` varchar(50) DEFAULT NULL,
  `cheque_date` date DEFAULT NULL,
  `bkash_merchant_number` varchar(50) DEFAULT NULL,
  `bkash_payment_number` varchar(50) DEFAULT NULL,
  `bkash_trx_id` varchar(50) DEFAULT NULL,
  `remarks` longtext DEFAULT NULL,
  `is_previous_due` tinyint(4) NOT NULL DEFAULT 0,
  `status` int(11) NOT NULL DEFAULT 1,
  `done_by` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `supplier_ledgers`
--

INSERT INTO `supplier_ledgers` (`id`, `ledger_date`, `supplier_id`, `supplier_invoice_no`, `invoice_no`, `debit`, `credit`, `payment_type`, `bank_name`, `cheque_no`, `cheque_date`, `bkash_merchant_number`, `bkash_payment_number`, `bkash_trx_id`, `remarks`, `is_previous_due`, `status`, `done_by`, `created_at`, `updated_at`) VALUES
(1, '2024-09-11', 1, NULL, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, ' ', '2024-09-11 12:47:09', '2024-09-11 12:47:09'),
(2, '2024-09-12', 2, NULL, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, ' ', '2024-09-12 05:28:28', '2024-09-12 05:28:28'),
(3, '2024-09-17', 3, NULL, 'Previous Due', 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Previous Due', 1, 1, ' ', '2024-09-17 22:13:39', '2024-09-17 22:13:39');

-- --------------------------------------------------------

--
-- Table structure for table `terminations`
--

CREATE TABLE `terminations` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `employee_id` int(11) NOT NULL DEFAULT 0,
  `notice_date` date NOT NULL,
  `termination_date` date NOT NULL,
  `description` varchar(191) DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `terminations`
--

INSERT INTO `terminations` (`id`, `employee_id`, `notice_date`, `termination_date`, `description`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 1, '2023-09-04', '2023-09-14', 'xcvcxvfdgfd', 1, '2023-09-03 23:56:01', '2023-09-03 23:56:01');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(191) NOT NULL,
  `email` varchar(191) NOT NULL,
  `profile_photo_path` varchar(2048) DEFAULT NULL,
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `password` varchar(191) NOT NULL,
  `avatar` varchar(191) DEFAULT NULL,
  `remember_token` varchar(100) DEFAULT NULL,
  `approved_index` int(11) DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `last_login_at` datetime DEFAULT NULL,
  `last_login_ip` varchar(191) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `profile_photo_path`, `email_verified_at`, `password`, `avatar`, `remember_token`, `approved_index`, `created_at`, `updated_at`, `last_login_at`, `last_login_ip`) VALUES
(1, 'Demo', 'demo@demo.com', NULL, '2023-07-25 04:29:51', '$2y$10$j8vCvW/x184cUEDz9BYjsuhrQq1dDRYApVcJpfYWD4ZEsoxI6.Upa', NULL, NULL, 0, '2023-07-25 04:29:51', '2024-11-28 23:17:44', '2024-11-28 18:17:44', '106.0.54.74'),
(27, 'Admin', 'admin@perfume.com', NULL, NULL, '$2y$10$4XPXQwS.SZzqe6SD/Tn97.mXWcl8Kq0Fk/x/MocguwzlSRwDHgOFq', NULL, NULL, 0, '2023-08-14 04:18:35', '2024-11-05 21:49:44', '2024-11-05 16:49:44', '106.0.54.74'),
(29, 'Masum', 'masum.azon@gmail.com', NULL, NULL, '$2y$10$4XPXQwS.SZzqe6SD/Tn97.mXWcl8Kq0Fk/x/MocguwzlSRwDHgOFq', NULL, 'Ha2MUS29iITg3WlGvHlSJXmT13RjJ94W3wPYiKU9OCkyWbjhbu7bdS3H8fQy', 0, '2023-09-19 01:43:09', '2024-05-30 06:24:38', '2024-01-16 10:23:52', '192.168.10.3'),
(30, 'Admin', 'admin@jago.com', NULL, NULL, '$2y$10$4XPXQwS.SZzqe6SD/Tn97.mXWcl8Kq0Fk/x/MocguwzlSRwDHgOFq', NULL, NULL, 0, '2023-09-19 22:45:46', '2024-11-28 22:41:45', '2024-11-28 17:41:45', '106.0.54.74'),
(31, 'Mr. Reza', 'reza@gmail.com', NULL, NULL, '$2y$10$4XPXQwS.SZzqe6SD/Tn97.mXWcl8Kq0Fk/x/MocguwzlSRwDHgOFq', NULL, NULL, 0, '2023-09-19 22:52:39', '2023-12-24 01:42:22', '2023-12-24 07:42:22', '192.168.10.2'),
(32, 'Perfume PLC', 'perfume@perfume.com', NULL, NULL, '$2y$10$RzDZI8QCHkWhkNZssa7W2OZ.vkrKB7Pay04iPcn9BsCXGHcji5kam', NULL, NULL, 0, '2023-10-04 06:13:43', '2024-05-16 08:38:27', '2024-05-16 14:38:02', '192.168.10.3'),
(33, 'HR', 'hr@demo.com', NULL, NULL, '$2y$10$4XPXQwS.SZzqe6SD/Tn97.mXWcl8Kq0Fk/x/MocguwzlSRwDHgOFq', NULL, NULL, 0, '2023-10-10 06:01:05', '2024-04-09 01:07:57', '2024-04-09 07:07:57', '127.0.0.1'),
(34, 'Mr. Salek', 'salek@gmail.com', NULL, NULL, '$2y$10$4XPXQwS.SZzqe6SD/Tn97.mXWcl8Kq0Fk/x/MocguwzlSRwDHgOFq', NULL, NULL, 0, '2023-10-10 06:11:15', '2023-11-20 05:38:45', '2023-11-20 11:38:45', '192.168.10.2'),
(35, 'CEO', 'ceo@perfume.com', NULL, NULL, '$2y$10$4XPXQwS.SZzqe6SD/Tn97.mXWcl8Kq0Fk/x/MocguwzlSRwDHgOFq', NULL, NULL, 2, '2023-10-12 00:21:57', '2024-07-04 12:20:44', '2024-07-04 18:20:44', '192.168.10.2'),
(38, 'Chemists', 'chemists@perfume.com', NULL, NULL, '$2y$10$4XPXQwS.SZzqe6SD/Tn97.mXWcl8Kq0Fk/x/MocguwzlSRwDHgOFq', NULL, NULL, 0, '2023-11-12 03:26:55', '2024-05-27 09:34:32', '2024-05-27 15:34:32', '192.168.10.3'),
(39, 'Store Incharge', 'storeincharge@perfume.com', NULL, NULL, '$2y$10$4XPXQwS.SZzqe6SD/Tn97.mXWcl8Kq0Fk/x/MocguwzlSRwDHgOFq', NULL, NULL, 3, '2023-11-20 05:11:02', '2024-06-04 09:38:16', '2024-06-04 15:38:16', '192.168.10.3'),
(41, 'Production Manager', 'promanager@perfume.com', NULL, NULL, '$2y$10$4XPXQwS.SZzqe6SD/Tn97.mXWcl8Kq0Fk/x/MocguwzlSRwDHgOFq', NULL, NULL, 1, '2023-11-22 01:52:58', '2024-07-03 05:43:43', '2024-07-03 11:43:43', '192.168.10.2');

-- --------------------------------------------------------

--
-- Table structure for table `warehouses`
--

CREATE TABLE `warehouses` (
  `id` int(11) NOT NULL,
  `company_code` varchar(200) DEFAULT '01',
  `code` varchar(255) DEFAULT NULL,
  `name` varchar(255) NOT NULL,
  `address` text DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `status` int(11) DEFAULT 1,
  `done_by` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `warehouses`
--

INSERT INTO `warehouses` (`id`, `company_code`, `code`, `name`, `address`, `description`, `status`, `done_by`, `created_at`, `updated_at`) VALUES
(1, '01', '001', 'Head Office (Main)', NULL, 'Main Warehouse', 1, 'Demo', '2024-09-03 07:48:46', '2024-09-11 08:27:14'),
(2, '01', '002', 'Mirpur Branch', NULL, 'Mirpur Warehouse', 1, 'Demo', '2024-09-03 08:07:35', '2024-09-10 06:22:30'),
(3, '01', '003', 'Gulshan Branch', NULL, 'Gulshan Warehouse', 1, 'Demo', '2024-09-03 08:40:31', '2024-09-10 06:22:39'),
(6, '01', '004', 'Dhanmondi Branch', NULL, 'Description  ..', 1, 'Demo', '2024-09-11 08:27:34', '2024-09-11 08:27:49');

-- --------------------------------------------------------

--
-- Table structure for table `weekend_days`
--

CREATE TABLE `weekend_days` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `weekend_day` varchar(50) DEFAULT NULL,
  `created_by` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `weekend_days`
--

INSERT INTO `weekend_days` (`id`, `weekend_day`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 'Friday', 'Demo', '2024-01-11 02:08:33', '2024-01-11 02:08:33'),
(2, 'Saturday', 'Demo', '2024-01-11 02:08:41', '2024-01-11 02:08:41');

-- --------------------------------------------------------

--
-- Table structure for table `work_times`
--

CREATE TABLE `work_times` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `start_time` time DEFAULT NULL,
  `end_time` time DEFAULT NULL,
  `created_by` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `work_times`
--

INSERT INTO `work_times` (`id`, `start_time`, `end_time`, `created_by`, `created_at`, `updated_at`) VALUES
(1, '09:00:00', '17:00:00', 'Demo', '2024-01-11 00:21:33', '2024-01-11 00:22:01');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `announcements`
--
ALTER TABLE `announcements`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `announcement_details`
--
ALTER TABLE `announcement_details`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `attendances`
--
ALTER TABLE `attendances`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `break_times`
--
ALTER TABLE `break_times`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `commissions`
--
ALTER TABLE `commissions`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `company_settings`
--
ALTER TABLE `company_settings`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `customers`
--
ALTER TABLE `customers`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `customer_ledgers`
--
ALTER TABLE `customer_ledgers`
  ADD PRIMARY KEY (`id`),
  ADD KEY `customer_ledgers_customer_id_foreign` (`customer_id`);

--
-- Indexes for table `customer_types`
--
ALTER TABLE `customer_types`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `deductions`
--
ALTER TABLE `deductions`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `employees`
--
ALTER TABLE `employees`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `employee_delayin_earlyouts`
--
ALTER TABLE `employee_delayin_earlyouts`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `employee_education`
--
ALTER TABLE `employee_education`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `employee_job_histories`
--
ALTER TABLE `employee_job_histories`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `employee_job_responsibilities`
--
ALTER TABLE `employee_job_responsibilities`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `employee_leave_entries`
--
ALTER TABLE `employee_leave_entries`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `employee_leave_settings`
--
ALTER TABLE `employee_leave_settings`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `employee_ledgers`
--
ALTER TABLE `employee_ledgers`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `employee_performances`
--
ALTER TABLE `employee_performances`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `employee_salaries`
--
ALTER TABLE `employee_salaries`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `emp_branches`
--
ALTER TABLE `emp_branches`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `emp_departments`
--
ALTER TABLE `emp_departments`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `emp_designations`
--
ALTER TABLE `emp_designations`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `emp_grades`
--
ALTER TABLE `emp_grades`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `emp_lines`
--
ALTER TABLE `emp_lines`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `emp_postings`
--
ALTER TABLE `emp_postings`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `emp_quite_types`
--
ALTER TABLE `emp_quite_types`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `emp_salary_sections`
--
ALTER TABLE `emp_salary_sections`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `emp_sections`
--
ALTER TABLE `emp_sections`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `emp_types`
--
ALTER TABLE `emp_types`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `failed_jobs`
--
ALTER TABLE `failed_jobs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`);

--
-- Indexes for table `finance_accounts`
--
ALTER TABLE `finance_accounts`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `finance_groups`
--
ALTER TABLE `finance_groups`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `group_code` (`group_code`);

--
-- Indexes for table `finance_transactions`
--
ALTER TABLE `finance_transactions`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `genrate_payslip_options`
--
ALTER TABLE `genrate_payslip_options`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `holidays`
--
ALTER TABLE `holidays`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `incomes`
--
ALTER TABLE `incomes`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `income_heads`
--
ALTER TABLE `income_heads`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `invoiceno`
--
ALTER TABLE `invoiceno`
  ADD PRIMARY KEY (`invoice_no_id`);

--
-- Indexes for table `late_times`
--
ALTER TABLE `late_times`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `loans`
--
ALTER TABLE `loans`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `loan_options`
--
ALTER TABLE `loan_options`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `meetings`
--
ALTER TABLE `meetings`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `migrations`
--
ALTER TABLE `migrations`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `model_has_permissions`
--
ALTER TABLE `model_has_permissions`
  ADD PRIMARY KEY (`permission_id`,`model_id`,`model_type`),
  ADD KEY `model_has_permissions_model_id_model_type_index` (`model_id`,`model_type`);

--
-- Indexes for table `model_has_roles`
--
ALTER TABLE `model_has_roles`
  ADD PRIMARY KEY (`role_id`,`model_id`,`model_type`),
  ADD KEY `model_has_roles_model_id_model_type_index` (`model_id`,`model_type`);

--
-- Indexes for table `monthly_salaries`
--
ALTER TABLE `monthly_salaries`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `monthly_salary_details`
--
ALTER TABLE `monthly_salary_details`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `notifications_notifiable_type_notifiable_id_index` (`notifiable_type`,`notifiable_id`);

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `order_details`
--
ALTER TABLE `order_details`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `other_payments`
--
ALTER TABLE `other_payments`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `overtimes`
--
ALTER TABLE `overtimes`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `password_resets`
--
ALTER TABLE `password_resets`
  ADD KEY `password_resets_email_index` (`email`);

--
-- Indexes for table `payrolls`
--
ALTER TABLE `payrolls`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `payroll_formulas`
--
ALTER TABLE `payroll_formulas`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `payroll_heads`
--
ALTER TABLE `payroll_heads`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `payslip_types`
--
ALTER TABLE `payslip_types`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `pay_slips`
--
ALTER TABLE `pay_slips`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `performance_types`
--
ALTER TABLE `performance_types`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `permissions`
--
ALTER TABLE `permissions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `permissions_name_guard_name_unique` (`name`,`guard_name`);

--
-- Indexes for table `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `personal_access_tokens_token_unique` (`token`),
  ADD KEY `personal_access_tokens_tokenable_type_tokenable_id_index` (`tokenable_type`,`tokenable_id`);

--
-- Indexes for table `productions`
--
ALTER TABLE `productions`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `production_bill_of_matrials`
--
ALTER TABLE `production_bill_of_matrials`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `products`
--
ALTER TABLE `products`
  ADD PRIMARY KEY (`id`),
  ADD KEY `products_supplier_id_foreign` (`supplier_id`),
  ADD KEY `products_category_id_foreign` (`category_id`),
  ADD KEY `products_sub_category_id_foreign` (`sub_category_id`),
  ADD KEY `products_brand_id_foreign` (`brand_id`),
  ADD KEY `products_color_id_foreign` (`color_id`),
  ADD KEY `products_size_id_foreign` (`size_id`),
  ADD KEY `products_unit_id_foreign` (`unit_id`);

--
-- Indexes for table `product_brands`
--
ALTER TABLE `product_brands`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `product_categories`
--
ALTER TABLE `product_categories`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `product_colors`
--
ALTER TABLE `product_colors`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `product_fragrances`
--
ALTER TABLE `product_fragrances`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `product_orders`
--
ALTER TABLE `product_orders`
  ADD PRIMARY KEY (`id`),
  ADD KEY `customer_id` (`customer_id`);

--
-- Indexes for table `product_order_details`
--
ALTER TABLE `product_order_details`
  ADD PRIMARY KEY (`id`),
  ADD KEY `product_order_id` (`product_order_id`);

--
-- Indexes for table `product_order_details_chains`
--
ALTER TABLE `product_order_details_chains`
  ADD PRIMARY KEY (`id`),
  ADD KEY `product_order_details_id` (`product_order_details_id`),
  ADD KEY `size_id` (`size_id`);

--
-- Indexes for table `product_services`
--
ALTER TABLE `product_services`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `product_service_details`
--
ALTER TABLE `product_service_details`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `product_sizes`
--
ALTER TABLE `product_sizes`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `product_sub_categories`
--
ALTER TABLE `product_sub_categories`
  ADD PRIMARY KEY (`id`),
  ADD KEY `product_sub_categories_category_id_foreign` (`category_id`);

--
-- Indexes for table `product_types`
--
ALTER TABLE `product_types`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `product_units`
--
ALTER TABLE `product_units`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `promotions`
--
ALTER TABLE `promotions`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `requisitions`
--
ALTER TABLE `requisitions`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `resignations`
--
ALTER TABLE `resignations`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `roles`
--
ALTER TABLE `roles`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `roles_name_guard_name_unique` (`name`,`guard_name`);

--
-- Indexes for table `role_has_permissions`
--
ALTER TABLE `role_has_permissions`
  ADD PRIMARY KEY (`permission_id`,`role_id`),
  ADD KEY `role_has_permissions_role_id_foreign` (`role_id`);

--
-- Indexes for table `set_salaries`
--
ALTER TABLE `set_salaries`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `stocks`
--
ALTER TABLE `stocks`
  ADD PRIMARY KEY (`id`),
  ADD KEY `stocks_supplier_id_foreign` (`supplier_id`),
  ADD KEY `stocks_product_id_foreign` (`product_id`),
  ADD KEY `stocks_customer_id_foreign` (`customer_id`);

--
-- Indexes for table `suppliers`
--
ALTER TABLE `suppliers`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `supplier_ledgers`
--
ALTER TABLE `supplier_ledgers`
  ADD PRIMARY KEY (`id`),
  ADD KEY `supplier_ledgers_supplier_id_foreign` (`supplier_id`);

--
-- Indexes for table `terminations`
--
ALTER TABLE `terminations`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `users_email_unique` (`email`);

--
-- Indexes for table `warehouses`
--
ALTER TABLE `warehouses`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `weekend_days`
--
ALTER TABLE `weekend_days`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `work_times`
--
ALTER TABLE `work_times`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `announcements`
--
ALTER TABLE `announcements`
  MODIFY `id` int(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `announcement_details`
--
ALTER TABLE `announcement_details`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=65;

--
-- AUTO_INCREMENT for table `attendances`
--
ALTER TABLE `attendances`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1724;

--
-- AUTO_INCREMENT for table `break_times`
--
ALTER TABLE `break_times`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `commissions`
--
ALTER TABLE `commissions`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `company_settings`
--
ALTER TABLE `company_settings`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `customers`
--
ALTER TABLE `customers`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=57;

--
-- AUTO_INCREMENT for table `customer_ledgers`
--
ALTER TABLE `customer_ledgers`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=46;

--
-- AUTO_INCREMENT for table `customer_types`
--
ALTER TABLE `customer_types`
  MODIFY `id` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `deductions`
--
ALTER TABLE `deductions`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `employees`
--
ALTER TABLE `employees`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=45;

--
-- AUTO_INCREMENT for table `employee_delayin_earlyouts`
--
ALTER TABLE `employee_delayin_earlyouts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT for table `employee_education`
--
ALTER TABLE `employee_education`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `employee_job_histories`
--
ALTER TABLE `employee_job_histories`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `employee_job_responsibilities`
--
ALTER TABLE `employee_job_responsibilities`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `employee_leave_entries`
--
ALTER TABLE `employee_leave_entries`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `employee_leave_settings`
--
ALTER TABLE `employee_leave_settings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `employee_ledgers`
--
ALTER TABLE `employee_ledgers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `employee_performances`
--
ALTER TABLE `employee_performances`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `employee_salaries`
--
ALTER TABLE `employee_salaries`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `emp_branches`
--
ALTER TABLE `emp_branches`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `emp_departments`
--
ALTER TABLE `emp_departments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `emp_designations`
--
ALTER TABLE `emp_designations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `emp_grades`
--
ALTER TABLE `emp_grades`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `emp_lines`
--
ALTER TABLE `emp_lines`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `emp_postings`
--
ALTER TABLE `emp_postings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `emp_quite_types`
--
ALTER TABLE `emp_quite_types`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `emp_salary_sections`
--
ALTER TABLE `emp_salary_sections`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `emp_sections`
--
ALTER TABLE `emp_sections`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `emp_types`
--
ALTER TABLE `emp_types`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `failed_jobs`
--
ALTER TABLE `failed_jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `finance_accounts`
--
ALTER TABLE `finance_accounts`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=169;

--
-- AUTO_INCREMENT for table `finance_groups`
--
ALTER TABLE `finance_groups`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT for table `finance_transactions`
--
ALTER TABLE `finance_transactions`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=691;

--
-- AUTO_INCREMENT for table `genrate_payslip_options`
--
ALTER TABLE `genrate_payslip_options`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `holidays`
--
ALTER TABLE `holidays`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `incomes`
--
ALTER TABLE `incomes`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `income_heads`
--
ALTER TABLE `income_heads`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `invoiceno`
--
ALTER TABLE `invoiceno`
  MODIFY `invoice_no_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=82;

--
-- AUTO_INCREMENT for table `late_times`
--
ALTER TABLE `late_times`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `loans`
--
ALTER TABLE `loans`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `loan_options`
--
ALTER TABLE `loan_options`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `meetings`
--
ALTER TABLE `meetings`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `migrations`
--
ALTER TABLE `migrations`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `monthly_salaries`
--
ALTER TABLE `monthly_salaries`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `monthly_salary_details`
--
ALTER TABLE `monthly_salary_details`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `order_details`
--
ALTER TABLE `order_details`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `other_payments`
--
ALTER TABLE `other_payments`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `overtimes`
--
ALTER TABLE `overtimes`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `payrolls`
--
ALTER TABLE `payrolls`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=31;

--
-- AUTO_INCREMENT for table `payroll_formulas`
--
ALTER TABLE `payroll_formulas`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `payroll_heads`
--
ALTER TABLE `payroll_heads`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `payslip_types`
--
ALTER TABLE `payslip_types`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `pay_slips`
--
ALTER TABLE `pay_slips`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT for table `performance_types`
--
ALTER TABLE `performance_types`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `permissions`
--
ALTER TABLE `permissions`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=298;

--
-- AUTO_INCREMENT for table `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `productions`
--
ALTER TABLE `productions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `production_bill_of_matrials`
--
ALTER TABLE `production_bill_of_matrials`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `products`
--
ALTER TABLE `products`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=69;

--
-- AUTO_INCREMENT for table `product_brands`
--
ALTER TABLE `product_brands`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `product_categories`
--
ALTER TABLE `product_categories`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `product_colors`
--
ALTER TABLE `product_colors`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `product_fragrances`
--
ALTER TABLE `product_fragrances`
  MODIFY `id` int(10) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `product_orders`
--
ALTER TABLE `product_orders`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `product_order_details`
--
ALTER TABLE `product_order_details`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `product_order_details_chains`
--
ALTER TABLE `product_order_details_chains`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `product_services`
--
ALTER TABLE `product_services`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `product_service_details`
--
ALTER TABLE `product_service_details`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `product_sizes`
--
ALTER TABLE `product_sizes`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=24;

--
-- AUTO_INCREMENT for table `product_sub_categories`
--
ALTER TABLE `product_sub_categories`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `product_types`
--
ALTER TABLE `product_types`
  MODIFY `id` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `product_units`
--
ALTER TABLE `product_units`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `promotions`
--
ALTER TABLE `promotions`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `requisitions`
--
ALTER TABLE `requisitions`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `resignations`
--
ALTER TABLE `resignations`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `roles`
--
ALTER TABLE `roles`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `set_salaries`
--
ALTER TABLE `set_salaries`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `stocks`
--
ALTER TABLE `stocks`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=670;

--
-- AUTO_INCREMENT for table `suppliers`
--
ALTER TABLE `suppliers`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2111;

--
-- AUTO_INCREMENT for table `supplier_ledgers`
--
ALTER TABLE `supplier_ledgers`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `terminations`
--
ALTER TABLE `terminations`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=46;

--
-- AUTO_INCREMENT for table `warehouses`
--
ALTER TABLE `warehouses`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `weekend_days`
--
ALTER TABLE `weekend_days`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `work_times`
--
ALTER TABLE `work_times`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `customer_ledgers`
--
ALTER TABLE `customer_ledgers`
  ADD CONSTRAINT `customer_ledgers_customer_id_foreign` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `model_has_permissions`
--
ALTER TABLE `model_has_permissions`
  ADD CONSTRAINT `model_has_permissions_permission_id_foreign` FOREIGN KEY (`permission_id`) REFERENCES `permissions` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `model_has_roles`
--
ALTER TABLE `model_has_roles`
  ADD CONSTRAINT `model_has_roles_role_id_foreign` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `product_orders`
--
ALTER TABLE `product_orders`
  ADD CONSTRAINT `customer_id` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`);

--
-- Constraints for table `product_order_details_chains`
--
ALTER TABLE `product_order_details_chains`
  ADD CONSTRAINT `size_id` FOREIGN KEY (`size_id`) REFERENCES `product_sizes` (`id`);

--
-- Constraints for table `role_has_permissions`
--
ALTER TABLE `role_has_permissions`
  ADD CONSTRAINT `role_has_permissions_permission_id_foreign` FOREIGN KEY (`permission_id`) REFERENCES `permissions` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `role_has_permissions_role_id_foreign` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
