{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE DeriveGeneric      #-}
{-# LANGUAGE OverloadedStrings  #-}
{-# LANGUAGE RecordWildCards    #-}
{-# LANGUAGE TypeFamilies       #-}

{-# OPTIONS_GHC -fno-warn-unused-imports #-}
{-# OPTIONS_GHC -fno-warn-unused-binds   #-}
{-# OPTIONS_GHC -fno-warn-unused-matches #-}

-- Derived from AWS service descriptions, licensed under Apache 2.0.

-- |
-- Module      : Network.AWS.IoT.TransferCertificate
-- Copyright   : (c) 2013-2015 Brendan Hay
-- License     : Mozilla Public License, v. 2.0.
-- Maintainer  : Brendan Hay <brendan.g.hay@gmail.com>
-- Stability   : auto-generated
-- Portability : non-portable (GHC extensions)
--
-- Transfers the specified certificate to the specified AWS account.
--
-- You can cancel the transfer until it is acknowledged by the recipient.
--
-- No notification is sent to the transfer destination\'s account, it is up
-- to the caller to notify the transfer target.
--
-- The certificate being transferred must not be in the ACTIVE state. It
-- can be deactivated using the UpdateCertificate API.
--
-- The certificate must not have any policies attached to it. These can be
-- detached using the DetachPrincipalPolicy API.
--
-- /See:/ <https://aws.amazon.com/iot#TransferCertificate.html AWS API Reference> for TransferCertificate.
module Network.AWS.IoT.TransferCertificate
    (
    -- * Creating a Request
      transferCertificate
    , TransferCertificate
    -- * Request Lenses
    , tcCertificateId
    , tcTargetAWSAccount

    -- * Destructuring the Response
    , transferCertificateResponse
    , TransferCertificateResponse
    -- * Response Lenses
    , tcrsTransferredCertificateARN
    , tcrsResponseStatus
    ) where

import           Network.AWS.IoT.Types
import           Network.AWS.IoT.Types.Product
import           Network.AWS.Prelude
import           Network.AWS.Request
import           Network.AWS.Response

-- | The input for the TransferCertificate operation.
--
-- /See:/ 'transferCertificate' smart constructor.
data TransferCertificate = TransferCertificate'
    { _tcCertificateId    :: !Text
    , _tcTargetAWSAccount :: !Text
    } deriving (Eq,Read,Show,Data,Typeable,Generic)

-- | Creates a value of 'TransferCertificate' with the minimum fields required to make a request.
--
-- Use one of the following lenses to modify other fields as desired:
--
-- * 'tcCertificateId'
--
-- * 'tcTargetAWSAccount'
transferCertificate
    :: Text -- ^ 'tcCertificateId'
    -> Text -- ^ 'tcTargetAWSAccount'
    -> TransferCertificate
transferCertificate pCertificateId_ pTargetAWSAccount_ =
    TransferCertificate'
    { _tcCertificateId = pCertificateId_
    , _tcTargetAWSAccount = pTargetAWSAccount_
    }

-- | The ID of the certificate.
tcCertificateId :: Lens' TransferCertificate Text
tcCertificateId = lens _tcCertificateId (\ s a -> s{_tcCertificateId = a});

-- | The AWS account.
tcTargetAWSAccount :: Lens' TransferCertificate Text
tcTargetAWSAccount = lens _tcTargetAWSAccount (\ s a -> s{_tcTargetAWSAccount = a});

instance AWSRequest TransferCertificate where
        type Rs TransferCertificate =
             TransferCertificateResponse
        request = patchJSON ioT
        response
          = receiveJSON
              (\ s h x ->
                 TransferCertificateResponse' <$>
                   (x .?> "transferredCertificateArn") <*>
                     (pure (fromEnum s)))

instance ToHeaders TransferCertificate where
        toHeaders = const mempty

instance ToJSON TransferCertificate where
        toJSON = const (Object mempty)

instance ToPath TransferCertificate where
        toPath TransferCertificate'{..}
          = mconcat
              ["/transfer-certificate/", toBS _tcCertificateId]

instance ToQuery TransferCertificate where
        toQuery TransferCertificate'{..}
          = mconcat ["targetAwsAccount" =: _tcTargetAWSAccount]

-- | The output from the TransferCertificate operation.
--
-- /See:/ 'transferCertificateResponse' smart constructor.
data TransferCertificateResponse = TransferCertificateResponse'
    { _tcrsTransferredCertificateARN :: !(Maybe Text)
    , _tcrsResponseStatus            :: !Int
    } deriving (Eq,Read,Show,Data,Typeable,Generic)

-- | Creates a value of 'TransferCertificateResponse' with the minimum fields required to make a request.
--
-- Use one of the following lenses to modify other fields as desired:
--
-- * 'tcrsTransferredCertificateARN'
--
-- * 'tcrsResponseStatus'
transferCertificateResponse
    :: Int -- ^ 'tcrsResponseStatus'
    -> TransferCertificateResponse
transferCertificateResponse pResponseStatus_ =
    TransferCertificateResponse'
    { _tcrsTransferredCertificateARN = Nothing
    , _tcrsResponseStatus = pResponseStatus_
    }

-- | The ARN of the certificate.
tcrsTransferredCertificateARN :: Lens' TransferCertificateResponse (Maybe Text)
tcrsTransferredCertificateARN = lens _tcrsTransferredCertificateARN (\ s a -> s{_tcrsTransferredCertificateARN = a});

-- | The response status code.
tcrsResponseStatus :: Lens' TransferCertificateResponse Int
tcrsResponseStatus = lens _tcrsResponseStatus (\ s a -> s{_tcrsResponseStatus = a});